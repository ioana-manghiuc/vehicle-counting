"""Model configuration and path resolution."""
from pathlib import Path
from fastapi import HTTPException
import logging

logger = logging.getLogger("app")


class ModelConfig:
    """Configuration for YOLO model paths and variants.
    
    Note: YOLO26 models are not yet available for auto-download from Ultralytics.
    Once they are released, add them back to OFFICIAL_MODELS:
        'yolo26n-official': 'yolo26n.pt',
        'yolo26s-official': 'yolo26s.pt',
        'yolo26m-official': 'yolo26m.pt',
        'yolo26l-official': 'yolo26l.pt',
    """
    
    OFFICIAL_MODELS = {
        'yolo11': 'yolo11n.pt',
        'yolo11s-official': 'yolo11s.pt',
        'yolo11m-official': 'yolo11m.pt',
        'yolo11l-official': 'yolo11l.pt',
        'yolo26n-official': 'yolo26n.pt',
        'yolo26s-official': 'yolo26s.pt',
        'yolo26m-official': 'yolo26m.pt',
        'yolo26l-official': 'yolo26l.pt',
    }

    GPU_MODELS = {
        'yolo11n': 'yolo11n-firstgpu.pt',
        'yolo11s': 'yolo11s-firstgpu.pt',
        'yolo11m': 'yolo11m-firstgpu.pt',
        'yolo11l': 'yolo11l-firstgpu.pt',
        'yolo26s': 'yolo26s-firstgpu.pt',
        'yolo26n': 'yolo26n-firstgpu.pt',
        'yolo26m': 'yolo26m-firstgpu.pt',
        'yolo26l': 'yolo26l-firstgpu.pt'
    }

    CPU_MODELS = {
        'yolo11n-cpu': 'yolo11n-cpu.pt',
        'yolo11s-cpu16': 'yolo11s-cpu-b16.pt',
        'yolo11s-cpu32': 'yolo11s-cpu-b32.pt',
    }

    @classmethod
    def get_models_dir(cls) -> Path:
        """Get the base models directory."""
        return Path(__file__).resolve().parent.parent / "models"

    @classmethod
    def resolve_model_path(cls, model_name: str) -> str:
        """
        Resolve model name to actual file path.
        
        Args:
            model_name: Model identifier (e.g., 'yolo11n', 'yolo11s-official')
            
        Returns:
            str: Path to model file or model name for auto-download
            
        Raises:
            HTTPException: If model is unknown or not found
        """
        models_dir = cls.get_models_dir()
        
        if model_name in cls.OFFICIAL_MODELS:
            filename = cls.OFFICIAL_MODELS[model_name]
            model_path = models_dir / filename

            if not model_path.exists():
                logger.info("Official model not found locally, using Ultralytics auto-download: %s", filename)
                return filename  
            else:
                logger.info("Using local official Ultralytics model: %s", model_path)
                return str(model_path)
                
        elif model_name in cls.GPU_MODELS:
            filename = cls.GPU_MODELS[model_name]
            model_path = models_dir / "first-gpu-weights" / filename
            logger.info("Using GPU model from first-gpu-weights: %s", model_path)
            
            if not model_path.exists():
                raise HTTPException(404, f"Model not found: {model_path}")
            return str(model_path)
            
        elif model_name in cls.CPU_MODELS:
            filename = cls.CPU_MODELS[model_name]
            model_path = models_dir / "cpu-weights" / filename
            logger.info("Using CPU model from cpu-weights: %s", model_path)
            
            if not model_path.exists():
                raise HTTPException(404, f"Model not found: {model_path}")
            return str(model_path)
            
        else:
            raise HTTPException(400, f"Unknown model: {model_name}")
