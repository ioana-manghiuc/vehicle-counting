from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import cv2
import json
import logging
from pathlib import Path
from uuid import uuid4
from dotenv import load_dotenv

from vehicle_counter import VehicleCounter 
from yolo_counter import VehicleCounterYOLO11

load_dotenv()

app = FastAPI()

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

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.post("/upload_frame")
async def upload_frame(video: UploadFile = File(...)):
    video_path = os.path.join(UPLOAD_FOLDER, video.filename)
    with open(video_path, "wb") as f:
        f.write(await video.read())

    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    cap.set(cv2.CAP_PROP_POS_FRAMES, int(fps))
    ret, frame = cap.read()
    cap.release()

    if not ret:
        raise HTTPException(400, "Frame extraction failed")

    name = Path(video.filename).stem + ".png"
    path = os.path.join(FRAME_FOLDER, name)
    cv2.imwrite(path, frame)

    return {"thumbnail_url": f"/frames/{name}"}


@app.get("/frames/{filename}")
def get_frame(filename: str):
    path = os.path.join(FRAME_FOLDER, filename)
    if not os.path.exists(path):
        raise HTTPException(404)
    return FileResponse(path, media_type="image/png")


def validate_directions(directions):
    for d in directions:
        if "id" not in d:
            raise ValueError("Direction missing id")
        if "p1" not in d or "p2" not in d:
            raise ValueError(f"Direction {d.get('id', '?')} missing line points")
        if "from" not in d or "to" not in d:
            raise ValueError(f"Direction {d.get('id', '?')} missing from/to labels")

@app.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...),
    model_name: str = Form(default="best.pt"),
):
    """
    Process video with YOLO11 + ByteTrack and count vehicles across multiple directions.
    """
    try:
        directions_data = json.loads(directions)
        validate_directions(directions_data)    
        if not directions_data:
            raise ValueError("No directions provided")

        video_path = os.path.join(UPLOAD_FOLDER, f"{uuid4()}_{video.filename}")
        with open(video_path, "wb") as f:
            f.write(await video.read())

        model_path = os.path.join("models", model_name)
        if not os.path.exists(model_path):
            raise ValueError(f"Model not found: {model_path}")

        device = "cuda" if cv2.cuda.getCudaEnabledDeviceCount() > 0 else "cpu"
        yolo = VehicleCounterYOLO11(model_path=model_path, conf=0.45, imgsz=640, device=device)

        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        if not ret:
            raise ValueError("Cannot read first frame")
        frame_h, frame_w = frame.shape[:2]
        cap.release()

        counter = VehicleCounter(lines=directions_data, frame_w=frame_w, frame_h=frame_h)
        prev_positions = {}
        for dets_with_ids in yolo.track_video(video_path):
                tracks_to_update = []

        for d in dets_with_ids:
            tid = d["track_id"]
            x, y, w, h = d["bbox"]
            cx = (x + w / 2) / frame_w
            cy = (y + h / 2) / frame_h
            prev = prev_positions.get(tid)
            if prev:
                tracks_to_update.append({
                    "id": tid,
                    "previous": prev,
                    "current": (cx, cy)
                })
            prev_positions[tid] = (cx, cy)

        counter.update(tracks_to_update)

        results = counter.get_results()
        result_id = str(uuid4())
        out_path = os.path.join(RESULTS_FOLDER, f"{result_id}.json")
        with open(out_path, "w") as f:
            json.dump(results, f, indent=2)

        os.remove(video_path)

        return {**results, "results_id": result_id}

    except Exception as e:
        logger.exception("Vehicle counting failed")
        raise HTTPException(500, str(e))
    
if __name__ == "__main__": 
    import uvicorn 
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)