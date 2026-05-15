import 'package:flutter/foundation.dart';

class TTSService extends ChangeNotifier {
  bool _enabled = true;
  double _speechRate = 0.95;
  double _pitch = 1.0;
  String _currentLanguage = 'ko-KR';

  final Map<String, String> _languageMap = {
    'ko': 'ko-KR',
    'en': 'en-US',
    'ja': 'ja-JP',
    'zh': 'zh-CN',
    'vi': 'vi-VN',
    'th': 'th-TH',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'es': 'es-ES',
  };

  bool get isEnabled => _enabled;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get currentLanguage => _currentLanguage;

  Future<void> speak(String text) async {
    if (!_enabled || text.trim().isEmpty) return;
    final detected = _detectLanguage(text);
    final ttsLang = _languageMap[detected] ?? 'ko-KR';
    _currentLanguage = ttsLang;
    debugPrint('[TTS] $detected -> $ttsLang: ${text.substring(0, text.length.clamp(0, 50))}');
    notifyListeners();
  }

  String _detectLanguage(String text) {
    final korean = RegExp(r'[가-힣]');
    final japanese = RegExp(r'[あ-んア-ン]');
    final chinese = RegExp(r'[\u4e00-\u9fff]');
    final thai = RegExp(r'[ก-๛]');
    final vietnamese = RegExp(r'[àáâãèéêìíòóôõùúăđ]');
    final koreanCount = korean.allMatches(text).length;
    final japaneseCount = japanese.allMatches(text).length;
    final chineseCount = chinese.allMatches(text).length;
    final thaiCount = thai.allMatches(text).length;
    final vietnameseCount = vietnamese.allMatches(text).length;
    if (koreanCount > japaneseCount && koreanCount > chineseCount) return 'ko';
    if (japaneseCount > 0) return 'ja';
    if (chineseCount > 0) return 'zh';
    if (thaiCount > 0) return 'th';
    if (vietnameseCount > 0) return 'vi';
    return 'en';
  }

  Future<void> stop() async {
    debugPrint('[TTS] Stopped');
  }

  void toggle() {
    _enabled = !_enabled;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    notifyListeners();
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.8, 1.2);
    notifyListeners();
  }
}
