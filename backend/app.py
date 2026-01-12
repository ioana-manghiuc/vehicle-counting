from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import os
import cv2
from pathlib import Path
from uuid import uuid4
from typing import List
import json

app = FastAPI()

UPLOAD_FOLDER = "videos"
FRAME_FOLDER = "frames"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(FRAME_FOLDER, exist_ok=True)


@app.post("/upload_frame")
async def upload_video_and_get_frame(video: UploadFile = File(...)):

    video_stem = Path(video.filename).stem

    video_path = os.path.join(UPLOAD_FOLDER, video.filename)
    with open(video_path, "wb") as f:
        f.write(await video.read())

    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_number = int(fps * 1)  
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)

    ret, frame = cap.read()
    cap.release()

    if not ret:
        return {"error": "Failed to extract frame"}

    frame_filename = f"{video_stem}.png"
    frame_path = os.path.join(FRAME_FOLDER, frame_filename)
    cv2.imwrite(frame_path, frame)

    return {
        "thumbnail_url": f"/frames/{frame_filename}"
    }


@app.get("/frames/{filename}")
def get_frame(filename: str):
    path = os.path.join(FRAME_FOLDER, filename)
    return FileResponse(path, media_type="image/png")

@app.get("/frames/{filename}")
def get_frame(filename: str):
    path = os.path.join(FRAME_FOLDER, filename)
    if os.path.exists(path):
        return FileResponse(path, media_type="image/png")
    return {"error": "Frame not found"}

@app.post("/count_vehicles")
async def count_vehicles(
    video: UploadFile = File(...),
    directions: str = Form(...)
):
    """
    directions comes as a serialized list from Flutter
    """
    parsed_directions = json.loads(directions)

    # TODO: YOLO processing here later
    
    return {
        "status": "ok",
        "message": "Vehicle counting not implemented yet",
        "directions_count": len(parsed_directions),
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8000, reload=True)
