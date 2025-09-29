import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';

class OpenMessage implements Message<OpenResponse> {
  const OpenMessage(this.deviceName);
  final String deviceName;
}

class OpenResponse implements Response {
  const OpenResponse(this.handle);
  final SANEHandle handle;
}

class OpenMessageHandler
    extends MessageHandler<OpenMessage, OpenResponse, SANEBusContext> {
  const OpenMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  OpenResponse handle(OpenMessage message, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeHandlePointer = ffi.calloc<SANE_Handle>();
    final deviceNamePointer = message.deviceName.toSANEString();
    late final SANEHandle handle;

    try {
      final status = libsane.sane_open(deviceNamePointer, nativeHandlePointer);
      logger.finest('sane_open(${message.deviceName}) -> ${status.name}');

      status.check();

      handle = context.nativeHandles.createSANEHandle(
        nativeHandlePointer.value,
        message.deviceName,
      );
    } finally {
      ffi.calloc.free(nativeHandlePointer);
      ffi.calloc.free(deviceNamePointer);
    }

    return OpenResponse(handle);
  }
}
