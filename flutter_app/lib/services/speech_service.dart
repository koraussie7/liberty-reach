import 'dart:async';
import 'package:flutter/foundation.dart';

enum SpeechState { idle, listening, processing, error }

class SpeechService extends ChangeNotifier {
  SpeechState _state = SpeechState.idle;
  String _recognizedText = '';
  String _lastError = '';
  String _language = 'en-US';
  bool _isAvailable = false;

  SpeechState get state => _state;
  String get recognizedText => _recognizedText;
  String get lastError => _lastError;
  String get language => _language;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SpeechState.listening;

  Future<bool> initialize() async {
    _isAvailable = true;
    notifyListeners();
    return true;
  }

  Future<void> startListening({String? language}) async {
    if (language != null) _language = language;
    _state = SpeechState.listening;
    _recognizedText = '';
    notifyListeners();

    try {
      final mockWords = ['hello', 'how', 'are', 'you', 'test', 'message', 'voice', 'input'];
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_state != SpeechState.listening) return;
        _recognizedText += '${mockWords[i]} ';
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Speech error: $e';
      _state = SpeechState.error;
      notifyListeners();
    }
  }

  Future<String> stopListening() async {
    _state = SpeechState.processing;
    notifyListeners();

    final result = _recognizedText.trim();
    _state = SpeechState.idle;
    notifyListeners();
    return result;
  }

  void cancelListening() {
    _state = SpeechState.idle;
    _recognizedText = '';
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
