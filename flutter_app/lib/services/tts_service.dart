/// Platform-adaptive TTS service.
/// Web: uses browser SpeechSynthesis API via dart:js_interop.
/// Native: stub (TTS not available, graceful fallback).
export 'tts_service_web.dart'
  if (dart.library.io) 'tts_service_stub.dart';
