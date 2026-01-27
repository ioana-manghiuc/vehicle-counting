# VCount

## Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.14](https://www.python.org/downloads/)

## Installation

1. Download and extract the ZIP file

## Backend Setup

1. Navigate to the **backend** directory
2. Create and activate a virtual environment
   - Windows
     - Create: `py -m venv .venv`
     - Activate: `.venv\Scripts\activate`
   - macOS/Linux
     - Create: `python3.14 -m venv .venv`
     - Activate: `source .venv/bin/activate`
3. Upgrade pip: `pip install --upgrade pip`
4. Install dependencies: `pip install -r requirements.txt`
5. Start server: `uvicorn app.main:app --reload`
   - Server runs on http://127.0.0.1:8000

### Notes for PyTorch/YOLO installs
- If `torch`/`torchvision` fail to install from `requirements.txt` on your platform, install them first, then rerun step 4:
  - CPU-only (any OS): `pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu`
  - CUDA (Windows/Linux, NVIDIA GPU): choose the matching CUDA version, e.g. `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126`
- macOS (Apple Silicon) runs on CPU by default in this app (no CUDA).

### Linux system dependencies
- OpenCV may require system libraries. If you see import errors for `libGL`, install: `sudo apt-get update && sudo apt-get install -y libgl1`
- MP4 writing uses `mp4v` codec via OpenCV; most distros work out-of-the-box. If exporting annotated videos fails, ensure FFmpeg/codecs are present.

## Frontend Setup

1. Navigate to the **frontend** directory
2. Install dependencies: `flutter pub get`
3. Run application:
   - Windows: `flutter run -d windows`
   - macOS: `flutter run -d macos`
   - Linux: `flutter run -d linux`

**Note:** Both backend and frontend must be running simultaneously for the application to work.
