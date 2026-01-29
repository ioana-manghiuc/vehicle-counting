"""Video processing orchestration."""
import time
import logging
from typing import List, Dict
from app.utils.cancellation import is_cancelled
from app.services.frame_annotator import FrameAnnotator

logger = logging.getLogger("app")


class VideoProcessor:
    """Handles video frame processing with tracking and annotation."""
    
    def __init__(
        self,
        tracker,
        counter,
        directions_data: List[dict],
        writer,
        video_path: str,
        processing_id: str
    ):
        """
        Initialize video processor.
        
        Args:
            tracker: YOLOVehicleTracker instance
            counter: VehicleCounter instance
            directions_data: Original direction configuration
            writer: cv2.VideoWriter instance
            video_path: Path to input video
            processing_id: Unique processing identifier
        """
        self.tracker = tracker
        self.counter = counter
        self.directions_data = directions_data
        self.writer = writer
        self.video_path = video_path
        self.processing_id = processing_id
        self.annotator = FrameAnnotator()
    
    def process_frames(self) -> int:
        """
        Process all video frames with tracking, counting, and annotation.
        
        Returns:
            int: Total number of frames processed
        """
        frame_count = 0
        check_frequency = 0
        
        for frame_idx, detections, frame in self.tracker.track_video(self.video_path):
            if frame_idx % 5 == 0:
                check_frequency += 1
                if is_cancelled(self.processing_id):
                    logger.warning(
                        "CANCELLATION DETECTED at frame %d (check #%d)",
                        frame_idx, check_frequency
                    )
                    break
            elif is_cancelled(self.processing_id):
                logger.warning(
                    "CANCELLATION DETECTED at frame %d (unlogged check)", frame_idx
                )
                break
            
            if frame_idx % 10 == 0:
                logger.info(
                    f"Processing frame {frame_idx}, detections: {len(detections)}"
                )
            
            if len(detections) > 0:
                time.sleep(0.033)  

            self.counter.update(detections)
            frame_count = frame_idx
            
            overlay = self.annotator.annotate_frame(
                frame=frame,
                detections=detections,
                directions=self.counter.directions,
                counts=self.counter.counts,
                directions_data=self.directions_data
            )
            
            self.writer.write(overlay)
        
        return frame_count
