import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'js_helpers.dart';

/// Text-to-Speech service using browser SpeechSynthesis API
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
    if (!_isAvailable || text.isEmpty || _isSpeaking) return;

    try {
      _isSpeaking = true;
      notifyListeners();

      // Create SpeechSynthesisUtterance
      final ctor = jsGlobalGet('SpeechSynthesisUtterance'.toJS) as JSFunction;
      final utterance = jsReflectConstruct(ctor, text.toJS);

      // Set properties
      jsReflectSet(utterance, 'lang'.toJS, _language.toJS);
      jsReflectSet(utterance, 'rate'.toJS, _rate.toJS);
      jsReflectSet(utterance, 'pitch'.toJS, _pitch.toJS);
      jsReflectSet(utterance, 'volume'.toJS, _volume.toJS);

      // Bind event: onend
      final onEnd = _makeOnEnd();
      jsReflectSet(utterance, 'onend'.toJS, onEnd);

      // Bind event: onerror
      final onError = _makeOnError();
      jsReflectSet(utterance, 'onerror'.toJS, onError);

      // Speak!
      final synth = jsGlobalGet('speechSynthesis'.toJS) as JSObject;
      jsCallMethod(synth, 'speak', [utterance].toJS);
    } catch (e) {
      debugPrint('[TTS] speak error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  void stop() {
    try {
      final synth = jsGlobalGet('speechSynthesis'.toJS) as JSObject;
      jsCallMethod(synth, 'cancel');
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }

  void pause() {
    try {
      final synth = jsGlobalGet('speechSynthesis'.toJS) as JSObject;
      jsCallMethod(synth, 'pause');
    } catch (_) {}
  }

  void resume() {
    try {
      final synth = jsGlobalGet('speechSynthesis'.toJS) as JSObject;
      jsCallMethod(synth, 'resume');
    } catch (_) {}
  }

  JSFunction _makeOnEnd() {
    void handler(JSAny? args) {
      _isSpeaking = false;
      notifyListeners();
    }
    return handler.toJS;
  }

  JSFunction _makeOnError() {
    void handler(JSAny? args) {
      _isSpeaking = false;
      notifyListeners();
    }
    return handler.toJS;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
