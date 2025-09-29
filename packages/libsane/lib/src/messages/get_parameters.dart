import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class GetParametersMessage implements Message<GetParametersResponse> {
  const GetParametersMessage(this.handle);
  final SANEHandle handle;
}

class GetParametersResponse implements Response {
  const GetParametersResponse(this.parameters);
  final SANEParameters parameters;
}

class GetParametersMessageHandler extends MessageHandler<GetParametersMessage,
    GetParametersResponse, SANEBusContext> {
  const GetParametersMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetParametersResponse handle(
    GetParametersMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeParametersPointer = ffi.calloc<SANE_Parameters>();

    try {
      final status = libsane.sane_get_parameters(
        context.nativeHandles.get(message.handle),
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');
      status.check();

      final parameters = nativeParametersPointer.ref.toSANEParameters();
      logger.finest('  -> $parameters');

      return GetParametersResponse(parameters);
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }
}
