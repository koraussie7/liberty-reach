import 'dart:js_interop';

/// Web JS interop helpers for browser APIs

@JS('globalThis')
external JSObject get jsGlobalThis;

@JS('Reflect.set')
external bool jsReflectSet(JSObject target, JSString key, JSAny? value);

@JS('Reflect.get')
external JSAny? jsReflectGet(JSObject target, JSString key);

@JS('Reflect.has')
external bool jsReflectHas(JSObject target, JSString key);

@JS('Reflect.construct')
external JSObject jsReflectConstruct(JSFunction target, [JSAny? arg]);

@JS('Reflect.apply')
external JSAny? jsReflectApply(JSFunction fn, JSObject? thisArg, JSArray<JSAny?> args);

/// Check if a global property exists
bool jsHas(String name) {
  return jsReflectHas(jsGlobalThis, name.toJS);
}

/// Get a global property
JSAny? jsGlobalGet(JSString name) {
  return jsReflectGet(jsGlobalThis, name);
}

/// Convert JSAny? to JSObject
JSObject jsToObj(JSAny? value) => value as JSObject;

/// Call a method on a JS object by name
JSAny? jsCallMethod(JSObject obj, String method, [JSArray<JSAny?>? args]) {
  final fn = jsReflectGet(obj, method.toJS);
  if (fn is JSFunction) {
    return jsReflectApply(fn, obj, args ?? <JSAny?>[].toJS);
  }
  return null;
}

/// Get array element by index
JSAny? jsArrayGet(JSObject arr, int index) {
  final fn = jsReflectGet(arr, 'item'.toJS);
  if (fn is JSFunction) {
    return jsReflectApply(fn, arr, [index.toJS].toJS);
  }
  return jsReflectGet(arr, index.toString().toJS);
}
