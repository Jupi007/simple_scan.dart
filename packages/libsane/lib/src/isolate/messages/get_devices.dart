import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class GetDevicesMessage implements IsolateMessage<GetDevicesResponse> {
  const GetDevicesMessage(this.localOnly);
  final bool localOnly;
}

class GetDevicesResponse implements IsolateResponse {
  const GetDevicesResponse(this.devices);
  final List<SaneDevice> devices;
}

class GetDevicesMessageHandler
    implements IsolateMessageHandler<GetDevicesMessage, GetDevicesResponse> {
  const GetDevicesMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  GetDevicesResponse handle(
    GetDevicesMessage message,
    SaneIsolateContext context,
  ) {
    if (!context.initialized) throw SaneNotInitializedError();

    final deviceListPointer =
        ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();

    try {
      final status = libSane.sane_get_devices(
        deviceListPointer,
        message.localOnly.toSaneBool(),
      );
      isolateLogger.finest('sane_get_devices() -> ${status.name}');

      status.check();

      final devices = <SaneDevice>[];
      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final nativeDevice = deviceListPointer.value[i].ref;
        devices.add(nativeDevice.toSaneDevice());
      }

      return GetDevicesResponse(
        List.unmodifiable(devices),
      );
    } finally {
      ffi.calloc.free(deviceListPointer);
    }
  }
}
