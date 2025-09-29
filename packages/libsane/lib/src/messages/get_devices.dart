import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class GetDevicesMessage implements Message<GetDevicesResponse> {
  const GetDevicesMessage(this.localOnly);
  final bool localOnly;
}

class GetDevicesResponse implements Response {
  const GetDevicesResponse(this.devices);
  final List<SANEDevice> devices;
}

class GetDevicesMessageHandler extends MessageHandler<GetDevicesMessage,
    GetDevicesResponse, SANEBusContext> {
  const GetDevicesMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetDevicesResponse handle(
    GetDevicesMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final deviceListPointer =
        ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();

    try {
      final status = libsane.sane_get_devices(
        deviceListPointer,
        message.localOnly.toSANEBool(),
      );
      logger.finest('sane_get_devices() -> ${status.name}');

      status.check();

      final devices = <SANEDevice>[];
      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final device = deviceListPointer.value[i].ref.toSANEDevice();
        devices.add(device);
        logger.finest('  -> $device');
      }

      return GetDevicesResponse(
        List.unmodifiable(devices),
      );
    } finally {
      ffi.calloc.free(deviceListPointer);
    }
  }
}
