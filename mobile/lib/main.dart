// WhisperSub Mobile — Android (.apk) + iOS (.ipa)
// Engine: whisper.cpp (goi whisper_ggml) — chay combo CPU + GPU tich hop
// (Android: NEON/CPU, iOS: CPU + Metal). Dien thoai khong co GPU roi nen
// KHONG co lua chon CPU/GPU rieng nhu ban desktop.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() => runApp(const WhisperSubApp());

/// Model cho mobile — chi tiny/base/small (model to hon se het RAM tren dien thoai).
/// Model duoc thu vien tu dong tai tu Hugging Face (repo ggerganov/whisper.cpp)
/// lan dau su dung, dung y tuong "chon model nao tai model day".
const kModels = <String, WhisperModel>{
  'tiny (~75MB)': WhisperModel.tiny,
  'base (~142MB)': WhisperModel.base,
  'small (~466MB)': WhisperModel.small,
};

/// Ngon ngu audio (auto = tu nhan dien)
const kLanguages = <String, String>{
  '🌐 Auto-detect': 'auto',
  'Tiếng Việt (vi)': 'vi',
  'English (en)': 'en',
  '日本語 (ja)': 'ja',
  '中文 (zh)': 'zh',
  '한국어 (ko)': 'ko',
  'Français (fr)': 'fr',
  'Español (es)': 'es',
  'ไทย (th)': 'th',
  'Bahasa Indonesia (id)': 'id',
};

class WhisperSubApp extends StatelessWidget {
  const WhisperSubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'WhisperSub',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = WhisperController();

  String modelKey = 'tiny (~75MB)';
  String langKey = '🌐 Auto-detect';
  String? filePath;
  bool busy = false;
  final logs = <String>['Sẵn sàng. Chọn file audio, model và ngôn ngữ rồi bấm Tách phụ đề.'];

  void log(String msg) => setState(() => logs.add(msg));

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'wav', 'm4a', 'aac', 'flac', 'ogg'],
    );
    if (result?.files.single.path != null) {
      setState(() => filePath = result!.files.single.path);
    }
  }

  Future<void> transcribe() async {
    if (filePath == null) {
      log('⚠️ Chưa chọn file!');
      return;
    }
    setState(() => busy = true);
    try {
      final model = kModels[modelKey]!;
      final lang = kLanguages[langKey]!;
      log('▶ Model: $modelKey | Ngôn ngữ: $lang');
      log('[1/2] Tải model từ Hugging Face nếu chưa có, rồi transcribe...');

      final result = await controller.transcribe(
        model: model,
        audioPath: filePath!,
        lang: lang,
      );

      final text = result?.transcription.text ?? '';
      if (text.isEmpty) {
        log('❌ Không nhận được text — thử model to hơn hoặc file khác.');
      } else {
        log('[2/2] ✅ Xong!');
        // Xuat file .srt canh file goc (neu co timestamps) hoac .txt
        final srt = _toSrt(result!);
        final outPath = '${filePath!.replaceAll(RegExp(r'\.[^.]+$'), '')}.srt';
        await File(outPath).writeAsString(srt);
        log('✅ Đã lưu: $outPath');
        await Share.shareXFiles([XFile(outPath)], text: 'Phụ đề từ WhisperSub');
      }
    } catch (e) {
      log('❌ Lỗi: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  String _toSrt(WhisperTranscribeResponse result) {
    final segments = result.transcription.segments;
    if (segments == null || segments.isEmpty) return result.transcription.text;
    final buf = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      buf
        ..writeln(i + 1)
        ..writeln('${_fmt(s.fromTs)} --> ${_fmt(s.toTs)}')
        ..writeln(s.text.trim())
        ..writeln();
    }
    return buf.toString();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)},$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhisperSub 🎬')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : pickFile,
              icon: const Icon(Icons.audio_file),
              label: Text(filePath?.split('/').last ?? 'Chọn file audio (mp3/mp4/wav...)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: modelKey,
              decoration: const InputDecoration(labelText: 'Model Whisper (tự tải từ Hugging Face)'),
              items: [for (final k in kModels.keys) DropdownMenuItem(value: k, child: Text(k))],
              onChanged: busy ? null : (v) => setState(() => modelKey = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: langKey,
              decoration: const InputDecoration(labelText: 'Ngôn ngữ audio'),
              items: [for (final k in kLanguages.keys) DropdownMenuItem(value: k, child: Text(k))],
              onChanged: busy ? null : (v) => setState(() => langKey = v!),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : transcribe,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.subtitles),
              label: Text(busy ? 'Đang xử lý...' : 'Tách phụ đề'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [for (final l in logs) Text(l)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
