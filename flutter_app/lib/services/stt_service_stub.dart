import 'package:flutter/foundation.dart';
import 'js_helpers.dart';

/// Speech-to-Text service — native stub (no Web Speech API available).
enum SttState { idle, listening, processing, done, error }

class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  String _recognizedText = '';
  String _interimText = '';
  String _lastError = '';
  String _language = 'ko-KR';
  bool _isAvailable = false;

  SttState get state => _state;
  String get recognizedText => _recognizedText;
  String get interimText => _interimText;
  String get lastError => _lastError;
  String get language => _language;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SttState.listening;

  Future<bool> initialize() async {
    try {
      _isAvailable = jsHas('webkitSpeechRecognition') || jsHas('SpeechRecognition');
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _lastError = 'STT init error: $e';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening({String? language}) async {
    if (_state == SttState.listening) return;
    if (language != null) _language = language;
    _lastError = '음성인식은 웹에서만 지원됩니다';
    _state = SttState.error;
    notifyListeners();
  }

  Future<String> stopListening() async {
    _state = SttState.idle;
    notifyListeners();
    return '';
  }

  void cancelListening() {
    _state = SttState.idle;
    notifyListeners();
  }

  void reset() {
    _recognizedText = '';
    _interimText = '';
    _lastError = '';
    _state = SttState.idle;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
  }

  @override
  void dispose() {
    cancelListening();
    super.dispose();
  }
}
