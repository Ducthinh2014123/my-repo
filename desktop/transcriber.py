"""Engine transcribe 2 backend:
- openai-whisper chinh chu cho model goc (tiny -> large-v3-turbo)
- transformers cho model fine-tune tren Hugging Face (PhoWhisper, kotoba, ...)
"""
import os
import sys

from models import OFFICIAL_MODELS, HF_MODELS

APP_NAME = "WhisperSub"


def models_dir() -> str:
    """Thu muc luu model (ghi duoc, khong nam trong Program Files)."""
    if sys.platform == "win32":
        base = os.environ.get("APPDATA", os.path.expanduser("~"))
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support")
    else:
        base = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    path = os.path.join(base, APP_NAME, "models")
    os.makedirs(path, exist_ok=True)
    return path


def resource_path(rel: str) -> str:
    """Duong dan resource khi chay tu PyInstaller bundle hoac tu source."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, rel)


def setup_ffmpeg_path() -> None:
    """Them ffmpeg bundle kem (neu co) vao PATH de whisper goi duoc."""
    bundled = resource_path("bin")
    if os.path.isdir(bundled):
        os.environ["PATH"] = bundled + os.pathsep + os.environ.get("PATH", "")


def gpu_available() -> bool:
    try:
        import torch
        return torch.cuda.is_available()
    except Exception:
        return False


def transcribe(file_path, model_key, device="cpu", language=None, log=print):
    """Transcribe file audio/video.

    Returns:
        (segments, detected_language)
        segments: list[dict] voi keys: start (float, giay), end (float), text (str)
    """
    if model_key in OFFICIAL_MODELS:
        return _transcribe_official(file_path, model_key, device, language, log)
    if model_key in HF_MODELS:
        return _transcribe_hf(file_path, model_key, device, language, log)
    raise ValueError(f"Model khong ho tro: {model_key}")


def _transcribe_official(file_path, model_key, device, language, log):
    import whisper  # openai-whisper chinh chu

    log(f"[1/3] Tải/khởi tạo model chính chủ '{model_key}' (device={device})...")
    model = whisper.load_model(model_key, device=device, download_root=models_dir())

    log("[2/3] Đang transcribe... (file dài sẽ lâu, kiên nhẫn nhé)")
    result = model.transcribe(
        file_path,
        language=language,          # None = auto-detect
        fp16=(device == "cuda"),
        verbose=False,
    )

    log("[3/3] Xong, đang chuẩn hóa segments...")
    segments = [
        {"start": float(s["start"]), "end": float(s["end"]), "text": s["text"].strip()}
        for s in result["segments"]
    ]
    return segments, result.get("language") or (language or "auto")


def _transcribe_hf(file_path, model_key, device, language, log):
    import torch
    from transformers import pipeline

    repo_id = HF_MODELS[model_key]
    log(f"[1/3] Tải/khởi tạo model Hugging Face '{repo_id}' (device={device})...")

    pipe = pipeline(
        "automatic-speech-recognition",
        model=repo_id,
        device=0 if device == "cuda" else -1,
        torch_dtype=torch.float16 if device == "cuda" else torch.float32,
        model_kwargs={"cache_dir": models_dir()},
        chunk_length_s=30,
        return_timestamps=True,
    )

    generate_kwargs = {"task": "transcribe"}
    if language:
        generate_kwargs["language"] = language

    log("[2/3] Đang transcribe... (file dài sẽ lâu, kiên nhẫn nhé)")
    result = pipe(file_path, generate_kwargs=generate_kwargs)

    log("[3/3] Xong, đang chuẩn hóa segments...")
    segments = []
    last_end = 0.0
    for chunk in result.get("chunks", []):
        ts = chunk.get("timestamp") or (None, None)
        start = ts[0] if ts[0] is not None else last_end
        end = ts[1] if ts[1] is not None else start + 5.0
        last_end = end
        text = (chunk.get("text") or "").strip()
        if text:
            segments.append({"start": float(start), "end": float(end), "text": text})

    # Truong hop model khong tra chunks (hiem): tra ve 1 segment full text
    if not segments and result.get("text"):
        segments = [{"start": 0.0, "end": 0.0, "text": result["text"].strip()}]

    return segments, language or "auto"
