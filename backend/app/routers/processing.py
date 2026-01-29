"""Vehicle counting processing endpoints."""
import os
import cv2
import json
import logging
import asyncio
from pathlib import Path
from uuid import uuid4
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.config.model_config import ModelConfig
from app.utils.direction_validator import validate_directions
from app.services.vehicle_counter import VehicleCounter
from app.services.yolo_tracker import YOLOVehicleTracker
from app.services.video_processor import VideoProcessor
from app.utils import cancellation

logger = logging.getLogger("app")

router = APIRouter(prefix="", tags=["processing"])

executor = ThreadPoolExecutor(max_workers=2)

UPLOAD_FOLDER = Path("videos")
RESULTS_FOLDER = Path("results")

UPLOAD_FOLDER.mkdir(exist_ok=True)
RESULTS_FOLDER.mkdir(exist_ok=True)


@router.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...),
    model_name: str = Form("yolo11n-best.pt"),
    intersection_name: str = Form(""),
    processing_id: str = Form(""),
):
    """Process video for vehicle counting with directional tracking."""
    try:
        logger.warning("count_vehicles called")
        logger.warning("   processing_id: %s", processing_id)
        logger.warning("   video.filename: %s", video.filename)
        logger.warning("   model_name: %s", model_name)
        logger.warning("   intersection_name: %s", intersection_name)
        
        # Register task for cancellation tracking
        cancellation.register_task(processing_id) 
        logger.warning("Registered task for processing_id: %s", processing_id)

        directions_data = json.loads(directions)
        validate_directions(directions_data)

        logger.info("Model: %s", model_name)
        logger.info("Directions count: %d", len(directions_data))

        for d in directions_data:
            logger.info(
                "Direction id=%s from=%s to=%s lines=%d",
                d["id"], d["from"], d["to"], len(d.get("lines", []))
            )

        # Save uploaded video
        video_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{video.filename}")
        with open(video_path, "wb") as f:
            f.write(await video.read())

        # Detect device
        device = "cuda" if cv2.cuda.getCudaEnabledDeviceCount() > 0 else "cpu"
        logger.info("Device selected: %s", device)

        # Get video properties
        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        if not ret:
            raise RuntimeError("Cannot read video")
        h, w = frame.shape[:2]
        fps = cap.get(cv2.CAP_PROP_FPS) or 30
        cap.release()
        
        logger.info(f"Video dimensions: {w}x{h}")

        # Resolve model path
        model_path = ModelConfig.resolve_model_path(model_name)
        
        # Initialize tracker and counter
        tracker = YOLOVehicleTracker(
            model_path=model_path,
            conf=0.45,
            imgsz=640,
            device=device,
        )

        counter = VehicleCounter(
            directions=directions_data,
            frame_w=w,
            frame_h=h,
        )

        # Setup video writer
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        annotated_filename = f"annotated_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}.mp4"
        annotated_path = os.path.join(RESULTS_FOLDER, annotated_filename)
        writer = cv2.VideoWriter(annotated_path, fourcc, fps, (w, h))
        
        logger.info("Starting vehicle counting...")
        start_time = datetime.now()

        # Process video frames
        processor = VideoProcessor(
            tracker=tracker,
            counter=counter,
            directions_data=directions_data,
            writer=writer,
            video_path=video_path,
            processing_id=processing_id
        )
        
        loop = asyncio.get_event_loop()
        frame_count = await loop.run_in_executor(
            executor,
            processor.process_frames
        )

        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        logger.info(f"Video processing complete: {frame_count} frames processed in {processing_time:.2f}s")
        writer.release()
        
        # Check if cancelled
        if cancellation.is_cancelled(processing_id):
            logger.warning("Task was cancelled - skipping results save and deleting annotated video")
            if os.path.exists(annotated_path):
                os.remove(annotated_path)
                logger.info(f"Deleted annotated video: {annotated_path}")
            cancellation.mark_completed(processing_id)
            return {"status": "cancelled", "processing_id": processing_id}
    
        # Generate results
        results = counter.get_results()
        
        results_with_metadata = {
            "results": results,
            "metadata": {
                "intersection_name": intersection_name,
                "video_file": video.filename,
                "model": model_name,
                "start_time": start_time.isoformat(),
                "end_time": end_time.isoformat(),
                "processing_time_seconds": round(processing_time, 2),
                "total_frames_processed": frame_count,
                "video_dimensions": {"width": w, "height": h},
                "directions_count": len(directions_data),
                "annotated_video": f"/results/{annotated_filename}",
                "input_fps": fps,
                "processed_fps": fps,
            }
        }

        # Save results to file
        result_filename = f"results_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}.json"
        result_path = os.path.join(RESULTS_FOLDER, result_filename)
        with open(result_path, 'w') as f:
            json.dump(results_with_metadata, f, indent=2)
        
        logger.info("Final results: %s", results)
        logger.info(f"Results saved to: {result_path}")
        
        cancellation.mark_completed(processing_id)
        return results_with_metadata

    except Exception as e:
        logger.exception("Vehicle counting failed")
        cancellation.mark_completed(processing_id, error=str(e))
        raise HTTPException(500, f"Vehicle counting failed: {str(e)}")


@router.post("/cancel_processing/{processing_id}")
def cancel_processing(processing_id: str):
    """Cancel a running vehicle counting process."""
    logger.warning("Received cancellation request for processing_id: %s", processing_id)
    
    task = cancellation.get_task_status(processing_id)
    
    if not task:
        logger.error("Processing ID %s not found", processing_id)
        return {"status": "not_found", "processing_id": processing_id}
    
    if task.get("completed"):
        logger.info("Processing_id %s already completed", processing_id)
        return {"status": "already_completed", "processing_id": processing_id}
    
    cancellation.mark_cancelled(processing_id)
    logger.warning("Marked processing_id %s as cancelled", processing_id)
    return {"status": "cancelled", "processing_id": processing_id}
