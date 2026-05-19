import 'package:flutter/foundation.dart';
import 'js_helpers.dart';

/// Native stub: TTS not available on this platform.
/// Uses JS helper stubs (which all return null/false on native).
class TtsService extends ChangeNotifier {
  bool _isSpeaking = false;
  bool _isAvailable = false;
  double _rate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _language = 'ko-KR';

  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get language => _language;

  Future<bool> initialize() async {
    try {
      _isAvailable = jsHas('speechSynthesis');
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      debugPrint('[TTS] init error: $e');
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  void setLanguage(String lang) {
    _language = lang;
  }

  void setRate(double rate) {
    _rate = rate.clamp(0.5, 2.0);
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  void speak(String text) {
    if (!_isAvailable || text.isEmpty) return;
    debugPrint('[TTS] speak not available on this platform: $text');
  }

  void stop() {
    _isSpeaking = false;
    notifyListeners();
  }

  void pause() {}

  void resume() {}

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
