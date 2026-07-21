"""Danh sach model va ngon ngu cho WhisperSub."""

# Model chinh chu OpenAI - tai qua thu vien openai-whisper (CDN cua OpenAI)
OFFICIAL_MODELS = [
    "tiny",
    "base",
    "small",
    "medium",
    "large",
    "large-v2",
    "large-v3",
    "large-v3-turbo",
]

# Model fine-tune tren Hugging Face - tai qua transformers
HF_MODELS = {
    "PhoWhisper-tiny": "vinai/PhoWhisper-tiny",
    "PhoWhisper-base": "vinai/PhoWhisper-base",
    "PhoWhisper-small": "vinai/PhoWhisper-small",
    "PhoWhisper-medium": "vinai/PhoWhisper-medium",
    "PhoWhisper-large": "vinai/PhoWhisper-large",
    "distil-large-v3": "distil-whisper/distil-large-v3",
    "kotoba-whisper-v2.0": "kotoba-tech/kotoba-whisper-v2.0",
    "whisper-large-v3-chinese": "Yisui/whisper-large-v3-chinese",
}

ALL_MODEL_KEYS = OFFICIAL_MODELS + list(HF_MODELS.keys())

# Ngon ngu cua file audio/video (None = auto-detect)
LANGUAGES = {
    "🌐 Auto-detect": None,
    "Tiếng Việt (vi)": "vi",
    "English (en)": "en",
    "日本語 (ja)": "ja",
    "中文 (zh)": "zh",
    "한국어 (ko)": "ko",
    "Français (fr)": "fr",
    "Deutsch (de)": "de",
    "Español (es)": "es",
    "Português (pt)": "pt",
    "Italiano (it)": "it",
    "Русский (ru)": "ru",
    "ไทย (th)": "th",
    "Bahasa Indonesia (id)": "id",
    "हिन्दी (hi)": "hi",
    "العربية (ar)": "ar",
    "Türkçe (tr)": "tr",
    "Nederlands (nl)": "nl",
    "Polski (pl)": "pl",
    "Українська (uk)": "uk",
}

SUPPORTED_MEDIA = [
    ("Media files", "*.mp3 *.mp4 *.wav *.m4a *.aac *.flac *.ogg *.opus *.mkv *.avi *.mov *.webm"),
    ("All files", "*.*"),
]
