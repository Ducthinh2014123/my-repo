#!/usr/bin/env bash
# ============================================================
# Build WhisperSub cho macOS -> WhisperSub.dmg (file tai cho Apple)
# Chay TREN MAY MAC:  bash build_macos.sh
# Yeu cau: python3.10+, ffmpeg (brew install ffmpeg), Xcode CLT
# Ghi chu: macOS khong co CUDA -> chi build ban CPU (Apple Silicon van nhanh)
# ============================================================
set -euo pipefail
VERSION="1.0.0"

cd "$(dirname "$0")/../.."   # -> desktop/

python3 -m venv venv-mac
source venv-mac/bin/activate
pip install --upgrade pip
pip install -r requirements-cpu.txt
pip install pyinstaller

# Bundle ffmpeg neu co bin/ffmpeg (tai ban static tu https://evermeet.cx/ffmpeg/)
ADD_FFMPEG=()
if [[ -f bin/ffmpeg ]]; then
  ADD_FFMPEG=(--add-binary "bin/ffmpeg:bin")
fi

# --windowed -> tao WhisperSub.app
pyinstaller main.py --name WhisperSub --windowed --noconfirm \
  "${ADD_FFMPEG[@]}" \
  --collect-data whisper \
  --collect-all transformers \
  --collect-all torch
  # Them icon: --icon assets/icon.icns (tao .icns tu icon.png bang iconutil)

# --- Dong thanh .dmg ---
mkdir -p dist-installer
hdiutil create -volname "WhisperSub" \
  -srcfolder "dist/WhisperSub.app" \
  -ov -format UDZO "dist-installer/WhisperSub-${VERSION}.dmg"

echo
echo "==== XONG! File: desktop/dist-installer/WhisperSub-${VERSION}.dmg ===="
echo "[i] Chua codesign/notarize nen Gatekeeper se chan lan dau:"
echo "    User phai chuot phai app -> Open, hoac: xattr -dr com.apple.quarantine /Applications/WhisperSub.app"
echo "[i] Muon het canh bao: can Apple Developer (\$99/nam) -> codesign + notarytool"
