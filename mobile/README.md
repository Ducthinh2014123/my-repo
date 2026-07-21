# WhisperSub Mobile — Android (.apk) + iOS (.ipa)

App Flutter dùng **whisper.cpp** (port chính thức của Whisper sang C/C++) — chạy combo **CPU + GPU tích hợp** (Android: CPU/NEON, iOS: CPU + Metal). Điện thoại không có GPU rời nên không có lựa chọn CPU/GPU riêng như desktop.

> ⚠️ **KHÔNG dùng được openai-whisper (PyTorch) trên mobile** — PyTorch không chạy tử tế trên điện thoại. whisper.cpp dùng đúng trọng số gốc của OpenAI convert sang GGML.

## Model hỗ trợ trên mobile

- `tiny` (~75MB), `base` (~142MB), `small` (~466MB) — tự tải từ Hugging Face lần đầu chọn.
- Model `medium/large` sẽ hết RAM trên hầu hết điện thoại — đừng bật.
- **PhoWhisper trên mobile:** cần convert sang GGML bằng script `models/convert-h5-to-ggml.py` của repo whisper.cpp:
  ```bash
  git clone https://github.com/ggerganov/whisper.cpp
  cd whisper.cpp
  python models/convert-h5-to-ggml.py /path/to/PhoWhisper-small . .
  # -> ggml-model.bin, tu host len HF/R2 roi tro URL trong app
  ```

## Chuẩn bị (1 lần)

```bash
# Cai Flutter SDK: https://docs.flutter.dev/get-started/install
cd mobile
flutter create . --platforms=android,ios --org com.milan.whispersub
flutter pub get
```

> `flutter create .` sinh thư mục `android/` và `ios/` chuẩn cho máy bạn (không commit sẵn trong zip để tránh lệch phiên bản Gradle/Xcode).

Sau khi sinh xong, mở `android/app/src/main/AndroidManifest.xml` thêm quyền:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## Build Android — .apk

```bash
# 1. Tao keystore de ky app (1 lan)
keytool -genkey -v -keystore ~/whispersub.jks -keyalg RSA -keysize 2048 -validity 10000 -alias whispersub

# 2. Tao file android/key.properties:
#    storePassword=***
#    keyPassword=***
#    keyAlias=whispersub
#    storeFile=/home/you/whispersub.jks
#    (va khai bao signingConfig trong android/app/build.gradle theo docs Flutter)

# 3. Build
flutter build apk --release            # -> build/app/outputs/flutter-apk/app-release.apk
flutter build apk --split-per-abi      # nhe hon: tach apk theo arm64-v8a / armeabi-v7a
```

## Build iOS — .ipa

**Bắt buộc:** máy **macOS** + **Xcode** + tài khoản **Apple Developer** ($99/năm).

```bash
cd mobile
flutter build ipa --release
# -> build/ios/ipa/whispersub_mobile.ipa
```

- Mở `ios/Runner.xcworkspace` trong Xcode → Signing & Capabilities → chọn Team để ký.
- Phân phối: upload TestFlight/App Store bằng Xcode Organizer hoặc `xcrun altool`. Sideload file .ipa trực tiếp rất hạn chế (AltStore/Sideloadly, ký lại 7 ngày/lần nếu tài khoản free).
- iOS tự dùng **Metal** để tăng tốc — không cần cấu hình gì thêm.

## Lưu ý về file mp4 trên mobile

whisper.cpp cần audio WAV 16kHz. Gói `whisper_ggml` tự xử lý đa số định dạng audio; với video mp4 nếu gặp lỗi, thêm gói `ffmpeg_kit_flutter` để tách audio trước:

```dart
await FFmpegKit.execute('-i input.mp4 -ar 16000 -ac 1 -c:a pcm_s16le out.wav');
```
