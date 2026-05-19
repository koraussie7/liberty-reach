import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'js_helpers.dart';

/// Speech-to-Text service using browser Web Speech API
enum SttState { idle, listening, processing, done, error }

class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  String _recognizedText = '';
  String _interimText = '';
  String _lastError = '';
  String _language = 'ko-KR';
  bool _isAvailable = false;

  JSObject? _recognition;
  JSFunction? _boundResult;
  JSFunction? _boundEnd;
  JSFunction? _boundError;

  SttState get state => _state;
  String get recognizedText => _recognizedText;
  String get interimText => _interimText;
  String get lastError => _lastError;
  String get language => _language;
  bool get isAvailable => _isAvailable;
  bool get isListening => _state == SttState.listening;

  Future<bool> initialize() async {
    try {
      _isAvailable = _webkitAvailable || _standardAvailable;
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _lastError = 'STT init error: $e';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  bool get _webkitAvailable => jsHas('webkitSpeechRecognition');
  bool get _standardAvailable => jsHas('SpeechRecognition');

  Future<void> startListening({String? language}) async {
    if (_state == SttState.listening) return;
    if (language != null) _language = language;

    try {
      _state = SttState.listening;
      _recognizedText = '';
      _interimText = '';
      _lastError = '';
      notifyListeners();

      // Get constructor
      final webkit = jsGlobalGet('webkitSpeechRecognition'.toJS);
      final ctor = (webkit is JSFunction ? webkit : jsGlobalGet('SpeechRecognition'.toJS)) as JSFunction;

      _recognition = jsReflectConstruct(ctor);
      final r = _recognition!;

      // Set properties
      jsReflectSet(r, 'lang'.toJS, _language.toJS);
      jsReflectSet(r, 'continuous'.toJS, true.toJS);
      jsReflectSet(r, 'interimResults'.toJS, true.toJS);
      jsReflectSet(r, 'maxAlternatives'.toJS, 3.toJS);

      // Event: onresult
      _boundResult = _buildOnResult();
      jsReflectSet(r, 'onresult'.toJS, _boundResult!);

      // Event: onend
      _boundEnd = _buildOnEnd();
      jsReflectSet(r, 'onend'.toJS, _boundEnd!);

      // Event: onerror
      _boundError = _buildOnError();
      jsReflectSet(r, 'onerror'.toJS, _boundError!);

      // Start recognition
      jsCallMethod(r, 'start');
    } catch (e) {
      _lastError = '시작 실패: $e';
      _state = SttState.error;
      notifyListeners();
    }
  }

  Future<String> stopListening() async {
    if (_state != SttState.listening) return _recognizedText;

    try {
      if (_recognition != null) {
        jsCallMethod(_recognition!, 'stop');
      }
      _state = SttState.processing;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      final result = _recognizedText.isNotEmpty ? _recognizedText : _interimText;
      _recognizedText = result.trim();

      if (_recognizedText.isEmpty) {
        _lastError = '음성을 인식하지 못했어요';
        _state = SttState.error;
      } else {
        _state = SttState.done;
      }
      notifyListeners();
      return _recognizedText;
    } catch (e) {
      _lastError = '중지 오류: $e';
      _state = SttState.error;
      notifyListeners();
      return _recognizedText;
    } finally {
      _cleanup();
    }
  }

  void cancelListening() {
    try {
      if (_recognition != null) {
        jsCallMethod(_recognition!, 'abort');
      }
    } catch (_) {}
    _cleanup();
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
    if (_recognition != null) {
      jsReflectSet(_recognition!, 'lang'.toJS, lang.toJS);
    }
  }

  void _cleanup() {
    _recognition = null;
    _boundResult = null;
    _boundEnd = null;
    _boundError = null;
    _interimText = '';
  }

  // --- Event Handlers ---

  JSFunction _buildOnResult() {
    void handler(JSAny? args) {
      try {
        if (args == null) return;
        final event = jsToObj(args);
        final results = jsToObj(jsReflectGet(event, 'results'.toJS));
        final len = (jsReflectGet(results, 'length'.toJS) as JSNumber).toDartInt;

        String finalText = '';
        String interim = '';
        for (int i = 0; i < len; i++) {
          final result = jsToObj(jsArrayGet(results, i));
          final isFinal = (jsReflectGet(result, 'isFinal'.toJS) as JSBoolean).toDart;
          final alt = jsToObj(jsArrayGet(result, 0));
          final transcript = (jsReflectGet(alt, 'transcript'.toJS) as JSString).toDart;

          if (isFinal) {
            finalText += transcript;
          } else {
            interim += transcript;
          }
        }

        if (finalText.isNotEmpty) _recognizedText = finalText;
        _interimText = interim;
        notifyListeners();
      } catch (e) {
        debugPrint('[STT] result error: $e');
      }
    }
    return handler.toJS;
  }

  JSFunction _buildOnEnd() {
    void handler(JSAny? args) {
      if (_state == SttState.listening) {
        _state = SttState.processing;
        notifyListeners();
      }
    }
    return handler.toJS;
  }

  JSFunction _buildOnError() {
    void handler(JSAny? args) {
      try {
        if (args == null) return;
        final event = jsToObj(args);
        final error = jsReflectGet(event, 'error'.toJS);
        _lastError = error is JSString ? '오류: ${error.toDart}' : '인식 오류가 발생했어요';
        _state = SttState.error;
        notifyListeners();
      } catch (e) {
        debugPrint('[STT] error: $e');
      }
    }
    return handler.toJS;
  }

  @override
  void dispose() {
    cancelListening();
    super.dispose();
  }
}
