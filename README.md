# WhisperSub — App tự động tách phụ đề bằng AI Whisper 🎬🔥

App tách phụ đề tự động từ file **mp3 / mp4 / wav / m4a / mkv...** dùng **OpenAI Whisper chính chủ** + các bản fine-tune trên Hugging Face (PhoWhisper, Kotoba, Distil, Chinese...).

## Tính năng

- ✅ Chọn model: `tiny`, `base`, `small`, `medium`, `large`, `large-v2`, `large-v3`, `large-v3-turbo`
- ✅ Model fine-tune HF: `vinai/PhoWhisper-{tiny,base,small,medium,large}`, `distil-whisper/distil-large-v3`, `kotoba-tech/kotoba-whisper-v2.0`, `Yisui/whisper-large-v3-chinese`
- ✅ Tự động tải model từ Hugging Face lần đầu chọn (lưu vào thư mục AppData/Local share)
- ✅ Chọn chạy **CPU** hoặc **GPU (CUDA)** — desktop
- ✅ Chọn ngôn ngữ audio hoặc **Auto-detect**
- ✅ Xuất phụ đề **SRT / VTT / TXT**
- ✅ Mobile (Android/iOS): dùng whisper.cpp (CPU + GPU tích hợp), model tiny/base/small

## Cấu trúc project

```
whisper-sub-app/
├── desktop/                  # App Windows / Linux / macOS (Python + Tkinter)
│   ├── main.py               # GUI
│   ├── transcriber.py        # Engine 2 backend (openai-whisper + transformers)
│   ├── models.py             # Danh sách model + ngôn ngữ
│   ├── subtitles.py          # Xuất SRT/VTT/TXT
│   ├── requirements-cpu.txt
│   ├── requirements-gpu.txt
│   ├── assets/icon.png / icon.ico
│   └── packaging/
│       ├── windows/          # build_windows.bat + installer.iss (Inno Setup) -> setup.exe
│       ├── linux/            # build_linux.sh -> .deb + .rpm
│       └── macos/            # build_macos.sh -> .dmg
├── mobile/                   # App Android (.apk) + iOS (.ipa) — Flutter + whisper.cpp
│   ├── pubspec.yaml
│   ├── lib/main.dart
│   └── README.md             # Hướng dẫn build apk/ipa chi tiết
└── .github/workflows/build.yml  # CI tự build tất cả nền tảng
```

## Quickstart (chạy thử desktop bằng Python)

```bash
cd desktop
python -m venv venv
# Windows: venv\Scripts\activate | Linux/macOS: source venv/bin/activate
pip install -r requirements-cpu.txt    # hoặc requirements-gpu.txt nếu có NVIDIA GPU
python main.py
```

> Cần cài **ffmpeg** trong PATH khi chạy dev (bản đóng gói đã bundle sẵn ffmpeg).

## Build từng nền tảng

| Nền tảng | Lệnh | Kết quả |
|---|---|---|
| Windows | `desktop\packaging\windows\build_windows.bat cpu` (hoặc `gpu`) | `WhisperSub-Setup-CPU.exe` |
| Linux | `bash desktop/packaging/linux/build_linux.sh cpu` | `.deb` + `.rpm` |
| macOS | `bash desktop/packaging/macos/build_macos.sh` | `WhisperSub.dmg` |
| Android | xem `mobile/README.md` | `app-release.apk` |
| iOS | xem `mobile/README.md` (cần Mac + Apple Developer) | `.ipa` |

## Lưu ý quan trọng

1. **Model chính chủ** (tiny → large-v3-turbo) tải từ CDN OpenAI qua thư viện `openai-whisper`. **Model fine-tune** (PhoWhisper, kotoba...) tải từ Hugging Face qua `transformers`. App tự chọn backend đúng.
2. Bản **GPU** yêu cầu NVIDIA GPU + driver mới (không cần cài CUDA toolkit — torch cu121 đã kèm runtime).
3. Model lưu tại:
   - Windows: `%APPDATA%\WhisperSub\models`
   - Linux: `~/.local/share/WhisperSub/models`
   - macOS: `~/Library/Application Support/WhisperSub/models`
4. RAM/VRAM tối thiểu: tiny/base ~1GB, small ~2GB, medium ~5GB, large ~10GB.
5. Windows SmartScreen sẽ cảnh báo file setup chưa ký — bấm *More info → Run anyway* (hoặc mua code-signing certificate).
