from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
import cv2
import json
import logging
import logging.config
from pathlib import Path
from uuid import uuid4
from datetime import datetime
from app.logging.logging_config import LOGGING_CONFIG
from app.services.vehicle_counter import VehicleCounter
from app.services.yolo_tracker import YOLOVehicleTracker

logging.config.dictConfig(LOGGING_CONFIG)

logger = logging.getLogger("app")

def resource_path(relative):
    """
    Get resource path for both development and packaged (PyInstaller) environments.
    In PyInstaller's onefile mode, sys._MEIPASS contains the temp extraction directory.
    In development, we resolve from the current file location.
    """
    if hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS) / relative
    return (Path(__file__).parent.parent.parent / relative).resolve()

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info("%s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("→ %d", response.status_code)
    return response


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_FOLDER = "videos"
FRAME_FOLDER = "frames"
RESULTS_FOLDER = "results"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(FRAME_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

@app.post("/upload_frame")
async def upload_frame(video: UploadFile = File(...)):
    logger.info("upload_frame: filename=%s", video.filename)

    video_path = os.path.join(UPLOAD_FOLDER, video.filename)
    with open(video_path, "wb") as f:
        f.write(await video.read())

    try:
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise HTTPException(400, "Failed to open video file")
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        logger.info("Video FPS: %s", fps)
        
        frame_index = max(0, int(fps) if fps > 0 else 30)  
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
        
        ret, frame = cap.read()
        cap.release()

        if not ret or frame is None:
            logger.error("Failed to extract frame at index %d", frame_index)
            raise HTTPException(400, "Frame extraction failed")

        name = Path(video.filename).stem + ".png"
        path = os.path.join(FRAME_FOLDER, name)
        success = cv2.imwrite(path, frame)
        
        if not success:
            logger.error("Failed to write frame to %s", path)
            raise HTTPException(500, "Failed to save frame")

        logger.info("Thumbnail written: %s", path)
        return {"thumbnail_url": f"/frames/{name}"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Unexpected error in upload_frame: %s", str(e))
        raise HTTPException(500, f"Unexpected error: {str(e)}")


@app.get("/frames/{filename}")
def get_frame(filename: str):
    logger.info("Serving frame: %s", filename)

    path = os.path.join(FRAME_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)

    return FileResponse(path, media_type="image/png")

@app.get("/results/{filename}")
def get_result_file(filename: str):
    logger.info("Serving result file: %s", filename)

    path = os.path.join(RESULTS_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)

    media_type = "application/octet-stream"
    if filename.endswith('.json'):
        media_type = "application/json"
    elif filename.endswith('.mp4'):
        media_type = "video/mp4"
    elif filename.endswith('.png'):
        media_type = "image/png"

    return FileResponse(path, media_type=media_type)


def validate_directions(directions):
    for d in directions:
        if "id" not in d:
            raise ValueError("Direction missing id")
        if "lines" not in d or len(d["lines"]) < 2:
            raise ValueError(f"Direction {d.get('id')} must have at least 2 lines (entry and exit)")
        if "from" not in d or "to" not in d:
            raise ValueError(f"Direction {d.get('id')} missing from/to labels")
        
        entry_count = sum(1 for line in d["lines"] if line.get("isEntry", False))
        exit_count = sum(1 for line in d["lines"] if not line.get("isEntry", True))
        
        if entry_count < 1:
            raise ValueError(f"Direction {d.get('id')} missing entry line (isEntry=true)")
        if exit_count < 1:
            raise ValueError(f"Direction {d.get('id')} missing exit line (isEntry=false)")


@app.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...),
    model_name: str = Form("yolo11n-best.pt"),
):
    try:
        logger.info("count_vehicles called")

        directions_data = json.loads(directions)
        validate_directions(directions_data)

        logger.info("Model: %s", model_name)
        logger.info("Directions count: %d", len(directions_data))

        for d in directions_data:
            logger.info(
                "Direction id=%s from=%s to=%s lines=%d",
                d["id"], d["from"], d["to"], len(d.get("lines", []))
            )

        video_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{video.filename}")
        with open(video_path, "wb") as f:
            f.write(await video.read())

        device = "cuda" if cv2.cuda.getCudaEnabledDeviceCount() > 0 else "cpu"
        logger.info("Device selected: %s", device)

        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        if not ret:
            raise RuntimeError("Cannot read video")
        h, w = frame.shape[:2]
        fps = cap.get(cv2.CAP_PROP_FPS) or 30
        cap.release()
        
        logger.info(f"Video dimensions: {w}x{h}")

        if not model_name.endswith('.pt'):
            model_name = f"{model_name}-best.pt"
        
        model_path = Path(__file__).resolve().parent.parent / "app" / "models" / model_name
        if not model_path.exists():
            raise HTTPException(404, f"Model not found: {model_path}")
        
        tracker = YOLOVehicleTracker(
            model_path=str(model_path),
            conf=0.45,
            imgsz=640,
            device=device,
        )

        counter = VehicleCounter(
            directions=directions_data,
            frame_w=w,
            frame_h=h,
        )

        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        processed_fps = fps  
        annotated_filename = f"annotated_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}.mp4"
        annotated_path = os.path.join(RESULTS_FOLDER, annotated_filename)
        writer = cv2.VideoWriter(annotated_path, fourcc, processed_fps, (w, h))

        logger.info("Starting vehicle counting...")
        start_time = datetime.now()
        frame_count = 0
        for frame_idx, detections, frame in tracker.track_video(video_path):
            if frame_idx % 10 == 0:
                logger.info(f"Processing frame {frame_idx}, detections: {len(detections)}")
            
            counter.update(detections)
            frame_count = frame_idx

            overlay = frame.copy()
            for d in counter.directions:
                dir_data = next((dd for dd in directions_data if dd['id'] == d['id']), None)
                if dir_data and 'color' in dir_data:
                    argb = dir_data['color']
                    b = (argb >> 0) & 0xFF
                    g = (argb >> 8) & 0xFF
                    r = (argb >> 16) & 0xFF
                    color_bgr = (b, g, r)
                else:
                    color_bgr = (255, 255, 255) 
                
                ex1, ey1, ex2, ey2 = int(d['entry_line']['x1']), int(d['entry_line']['y1']), int(d['entry_line']['x2']), int(d['entry_line']['y2'])
                cv2.line(overlay, (ex1, ey1), (ex2, ey2), color_bgr, 3)

                mid_x, mid_y = (ex1 + ex2) // 2, (ey1 + ey2) // 2
                cv2.putText(overlay, "ENTRY", (mid_x - 30, mid_y - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color_bgr, 2, cv2.LINE_AA)
                
                x1, y1, x2, y2 = int(d['exit_line']['x1']), int(d['exit_line']['y1']), int(d['exit_line']['x2']), int(d['exit_line']['y2'])
                cv2.line(overlay, (x1, y1), (x2, y2), color_bgr, 2, cv2.LINE_4)
                
                mid_x, mid_y = (x1 + x2) // 2, (y1 + y2) // 2
                cv2.putText(overlay, "EXIT", (mid_x - 25, mid_y + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color_bgr, 2, cv2.LINE_AA)

            for det in detections:
                x1, y1, x2, y2 = det['bbox']
                cx, cy = int(det['cx']), int(det['cy'])
                cv2.rectangle(overlay, (x1, y1), (x2, y2), (255, 255, 0), 2)
                cv2.circle(overlay, (cx, cy), 3, (0, 0, 255), -1)
                cv2.putText(overlay, f"ID {det['track_id']} cls {det['class_id']}", (x1, y1-8), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 1, cv2.LINE_AA)

            y_offset = 25
            for d in counter.directions:
                dir_id = d['id']
                
                dir_data = next((dd for dd in directions_data if dd['id'] == d['id']), None)
                if dir_data and 'color' in dir_data:
                    argb = dir_data['color']
                    b = (argb >> 0) & 0xFF
                    g = (argb >> 8) & 0xFF
                    r = (argb >> 16) & 0xFF
                    text_color = (b, g, r)
                else:
                    text_color = (50, 255, 50)
                
                label = f"{d['from']} -> {d['to']}: B:{counter.counts[dir_id]['bikes']} C:{counter.counts[dir_id]['cars']} Bu:{counter.counts[dir_id]['buses']} T:{counter.counts[dir_id]['trucks']}"
                
                (text_w, text_h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                cv2.rectangle(overlay, (15, y_offset - text_h - 5), (25 + text_w, y_offset + 5), (0, 0, 0), -1)
                cv2.rectangle(overlay, (15, y_offset - text_h - 5), (25 + text_w, y_offset + 5), text_color, 2)
                
                cv2.putText(overlay, label, (20, y_offset), cv2.FONT_HERSHEY_SIMPLEX, 0.6, text_color, 2, cv2.LINE_AA)
                y_offset += 35

            writer.write(overlay)

        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        logger.info(f"Video processing complete: {frame_count} frames processed in {processing_time:.2f}s")
        writer.release()
    
        results = counter.get_results()
        
        results_with_metadata = {
            "results": results,
            "metadata": {
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
                "processed_fps": processed_fps,
            }
        }

        result_filename = f"results_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}.json"
        result_path = os.path.join(RESULTS_FOLDER, result_filename)
        with open(result_path, 'w') as f:
            json.dump(results_with_metadata, f, indent=2)
        
        logger.info("Final results: %s", results)
        logger.info(f"Results saved to: {result_path}")

        return results_with_metadata

    except Exception as e:
        logger.exception("Vehicle counting failed")
        raise HTTPException(500, f"Vehicle counting failed: {str(e)}")


# Mount Flutter web build LAST, so API routes take precedence
WEB_DIR = resource_path(Path("frontend") / "build" / "web")
if WEB_DIR.exists():
    logger.info(f"Flutter web build found at {WEB_DIR}, mounting at root")
    app.mount("/", StaticFiles(directory=WEB_DIR, html=True), name="web")
else:
    logger.warning(f"Flutter web build not found at {WEB_DIR}. Web frontend will not be served.")