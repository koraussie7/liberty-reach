/// Platform-adaptive JS interop helpers.
/// Web: uses dart:js_interop for browser APIs.
/// Native: stub (returns null/false for all calls).
export 'js_helpers_web.dart'
  if (dart.library.io) 'js_helpers_stub.dart';
