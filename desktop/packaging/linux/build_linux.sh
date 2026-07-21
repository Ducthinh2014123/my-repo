#!/usr/bin/env bash
# ============================================================
# Build WhisperSub cho Linux -> .deb + .rpm
# Cach dung:  bash build_linux.sh cpu   (hoac: bash build_linux.sh gpu)
# Yeu cau: python3.10+, ffmpeg, ruby + gem fpm (gem install fpm)
# ============================================================
set -euo pipefail
VARIANT="${1:-cpu}"
VERSION="1.0.0"

cd "$(dirname "$0")/../.."   # -> desktop/

# --- venv + deps ---
python3 -m venv "venv-$VARIANT"
source "venv-$VARIANT/bin/activate"
pip install --upgrade pip
pip install -r "requirements-$VARIANT.txt"
pip install pyinstaller

# --- Bundle ffmpeg neu co trong bin/, khong thi khai bao dependency he thong ---
ADD_FFMPEG=()
if [[ -f bin/ffmpeg ]]; then
  ADD_FFMPEG=(--add-binary "bin/ffmpeg:bin")
  DEPENDS=()
else
  echo "[i] Khong co bin/ffmpeg — goi .deb/.rpm se depend vao ffmpeg he thong"
  DEPENDS=(-d ffmpeg)
fi

# --- PyInstaller (onedir) ---
pyinstaller main.py --name WhisperSub --noconfirm \
  "${ADD_FFMPEG[@]}" \
  --collect-data whisper \
  --collect-all transformers \
  --collect-all torch

# --- Chuan bi cay thu muc cai dat ---
STAGE="pkgroot"
rm -rf "$STAGE"
mkdir -p "$STAGE/opt/whispersub" "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor/256x256/apps" "$STAGE/usr/bin"
cp -r dist/WhisperSub/* "$STAGE/opt/whispersub/"
cp packaging/linux/whispersub.desktop "$STAGE/usr/share/applications/"
cp assets/icon.png "$STAGE/usr/share/icons/hicolor/256x256/apps/whispersub.png"
ln -sf /opt/whispersub/WhisperSub "$STAGE/usr/bin/whispersub"

# --- fpm -> .deb + .rpm ---
mkdir -p dist-installer
for TARGET in deb rpm; do
  EXTRA=()
  if [[ "$TARGET" == "rpm" ]]; then
    EXTRA=(--rpm-rpmbuild-define "_build_id_links none")
  fi
  fpm -s dir -t "$TARGET" \
    -n "whispersub-$VARIANT" -v "$VERSION" \
    --description "WhisperSub - AI subtitle generator (OpenAI Whisper, $VARIANT build)" \
    --url "https://github.com/yourname/whisper-sub-app" \
    --license MIT --vendor Milan \
    "${DEPENDS[@]}" "${EXTRA[@]}" \
    -p "dist-installer/whispersub-${VARIANT}_${VERSION}.$TARGET" \
    -C "$STAGE" .
done

echo
echo "==== XONG! File .deb/.rpm nam trong desktop/dist-installer/ ===="
echo "Cai thu:  sudo dpkg -i dist-installer/whispersub-${VARIANT}_${VERSION}.deb"
echo "          sudo rpm -i  dist-installer/whispersub-${VARIANT}_${VERSION}.rpm"
