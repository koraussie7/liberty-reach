/// Platform-adaptive STT service.
/// Web: uses browser Web Speech API via dart:js_interop.
/// Native: stub (STT not available, graceful fallback).
export 'stt_service_web.dart'
  if (dart.library.io) 'stt_service_stub.dart';
