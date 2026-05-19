/// Native stub: JS interop not available on this platform.
/// All methods return null or false.
bool jsHas(String name) => false;

void jsReflectSet(Object target, String key, Object? value) {}

Object? jsReflectGet(Object target, String key) => null;

bool jsReflectHas(Object target, String key) => false;

Object? jsGlobalGet(String name) => null;

Object? jsCallMethod(Object obj, String method, [List<Object?>? args]) => null;
