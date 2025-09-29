import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class GetOptionDescriptorMessage
    implements Message<GetOptionDescriptorResponse> {
  const GetOptionDescriptorMessage(this.handle, this.index);
  final SANEHandle handle;
  final int index;
}

class GetOptionDescriptorResponse implements Response {
  const GetOptionDescriptorResponse(this.optionDescriptor);
  final SANEOptionDescriptor? optionDescriptor;
}

class GetOptionDescriptorMessageHandler extends MessageHandler<
    GetOptionDescriptorMessage, GetOptionDescriptorResponse, SANEBusContext> {
  const GetOptionDescriptorMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetOptionDescriptorResponse handle(
    GetOptionDescriptorMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final optionDescriptorPointer = libsane.sane_get_option_descriptor(
      context.nativeHandles.get(message.handle),
      message.index,
    );
    logger.finest('sane_get_option_descriptor(${message.index})');

    if (optionDescriptorPointer == ffi.nullptr) {
      return const GetOptionDescriptorResponse(null);
    }

    final optionDescriptor = optionDescriptorPointer.ref
        .toSANEOptionDescriptorWithIndex(message.index);
    logger.finest('  -> $optionDescriptor');

    return GetOptionDescriptorResponse(optionDescriptor);
  }
}
