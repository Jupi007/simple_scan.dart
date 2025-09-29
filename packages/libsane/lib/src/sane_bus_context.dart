import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/structures.dart';

class NativeSANEHandleCollection {
  final Map<SANEHandle, SANE_Handle> _handlePointers = {};

  SANE_Handle get(SANEHandle handle) {
    if (!_handlePointers.containsKey(handle)) {
      throw SANEHandleClosedError(handle.deviceName);
    }

    return _handlePointers[handle]!;
  }

  SANEHandle createSANEHandle(SANE_Handle nativeHandle, String deviceName) {
    final handle = SANEHandle(deviceName);
    _handlePointers.addAll({
      handle: nativeHandle,
    });
    return handle;
  }

  void remove(SANEHandle handle) => _handlePointers.remove(handle);

  void clear() => _handlePointers.clear();
}

class SANEBusContext extends BusContext {
  bool initialized = false;
  final nativeHandles = NativeSANEHandleCollection();
  ffi.NativeCallable<SANE_Auth_CallbackFunction>? nativeAuthCallback;
}
