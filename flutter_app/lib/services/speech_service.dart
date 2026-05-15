import 'package:flutter/foundation.dart';

class SpeechService extends ChangeNotifier {
  bool _isListening = false;
  String _currentLocale = 'ko_KR';
  String _lastRecognizedText = '';
  bool _isAvailable = false;

  final Map<String, String> supportedLocales = {
    '한국어': 'ko_KR',
    'English': 'en_US',
    '日本語': 'ja_JP',
    '中文': 'zh_CN',
    'Tiếng Việt': 'vi_VN',
    'ภาษาไทย': 'th_TH',
    'Español': 'es_ES',
    'Français': 'fr_FR',
  };

  bool get isListening => _isListening;
  String get lastText => _lastRecognizedText;
  String get currentLocale => _currentLocale;
  bool get isAvailable => _isAvailable;

  Future<void> init() async {
    _isAvailable = true;
    notifyListeners();
  }

  Future<void> startListening(String localeKey, Function(String) onResult) async {
    final locale = supportedLocales[localeKey] ?? 'ko_KR';
    _currentLocale = locale;
    _isListening = true;
    _lastRecognizedText = '';
    notifyListeners();

    // Simulated STT for web - in production uses platform channel
    debugPrint('[SpeechService] Listening started: $localeKey ($locale)');

    _isListening = false;
    notifyListeners();
  }

  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
  }

  void setLocale(String localeKey) {
    final locale = supportedLocales[localeKey];
    if (locale != null) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  void simulateResult(String text) {
    _lastRecognizedText = text;
    notifyListeners();
  }
}
