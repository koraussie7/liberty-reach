import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum VoiceState { idle, recording, playing, hasRecording }

class VoiceService extends ChangeNotifier {
  VoiceState _state = VoiceState.idle;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  DateTime? _recordingStarted;
  int _amplitude = 0;

  VoiceState get state => _state;
  String? get recordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;
  int get amplitude => _amplitude;
  bool get isRecording => _state == VoiceState.recording;
  bool get isPlaying => _state == VoiceState.playing;

  Future<String> startRecording() async {
    _state = VoiceState.recording;
    _recordingDuration = Duration.zero;
    _recordingStarted = DateTime.now();
    notifyListeners();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = path;

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_recordingStarted != null) {
        _recordingDuration = DateTime.now().difference(_recordingStarted!);
        _amplitude = (_amplitude + 10) % 100;
        notifyListeners();
      }
    });

    return path;
  }

  Future<String?> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _state = VoiceState.hasRecording;
    notifyListeners();
    return _currentRecordingPath;
  }

  Future<Uint8List?> getRecordingBytes() async {
    if (_currentRecordingPath == null) return null;
    try {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('[Voice] read error: $e');
    }
    return null;
  }

  String encodeToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  Future<void> playRecording(String path) async {
    _state = VoiceState.playing;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[Voice] play error: $e');
    }

    _state = VoiceState.hasRecording;
    notifyListeners();
  }

  Future<void> playFromBytes(Uint8List bytes) async {
    _state = VoiceState.playing;
    notifyListeners();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_play_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await File(path).writeAsBytes(bytes);

    try {
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[Voice] play bytes error: $e');
    }

    _state = VoiceState.idle;
    notifyListeners();
  }

  void cancelRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _currentRecordingPath = null;
    _state = VoiceState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
