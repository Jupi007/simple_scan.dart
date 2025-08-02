import 'dart:ffi' as ffi;

import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/structures.dart';

class NativeSaneHandleCollection {
  final Map<SaneHandle, SANE_Handle> _handlePointers = {};

  SANE_Handle get(SaneHandle handle) {
    if (!_handlePointers.containsKey(handle)) {
      throw SaneHandleClosedError(handle.deviceName);
    }

    return _handlePointers[handle]!;
  }

  SaneHandle createSaneHandle(SANE_Handle nativeHandle, String deviceName) {
    final handle = SaneHandle(deviceName);
    _handlePointers.addAll({
      handle: nativeHandle,
    });
    return handle;
  }

  void remove(SaneHandle handle) => _handlePointers.remove(handle);

  void clear() => _handlePointers.clear();
}

class SaneIsolateContext {
  bool initialized = false;
  final nativeHandles = NativeSaneHandleCollection();
  ffi.NativeCallable<SANE_Auth_CallbackFunction>? nativeAuthCallback;
}
