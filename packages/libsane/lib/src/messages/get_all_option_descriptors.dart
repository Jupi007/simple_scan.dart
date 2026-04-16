import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class GetAllOptionDescriptorsMessage
    implements Message<GetAllOptionDescriptorsResponse> {
  const GetAllOptionDescriptorsMessage(this.handle);
  final SANEHandle handle;
}

class GetAllOptionDescriptorsResponse implements Response {
  const GetAllOptionDescriptorsResponse(this.optionDescriptors);
  final List<SANEOptionDescriptor> optionDescriptors;
}

class GetAllOptionDescriptorsMessageHandler extends MessageHandler<
    GetAllOptionDescriptorsMessage,
    GetAllOptionDescriptorsResponse,
    SANEBusContext> {
  const GetAllOptionDescriptorsMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetAllOptionDescriptorsResponse handle(
    GetAllOptionDescriptorsMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final optionDescriptors = <SANEOptionDescriptor>[];

    for (var i = 0;; i++) {
      final optionDescriptorPointer = libsane.sane_get_option_descriptor(
        context.nativeHandles.get(message.handle),
        i,
      );
      logger.finest('sane_get_option_descriptor($i)');
      // TODO better logging

      if (optionDescriptorPointer == ffi.nullptr) break;
      final optionDescriptor =
          optionDescriptorPointer.ref.toSANEOptionDescriptorWithIndex(i);
      optionDescriptors.add(optionDescriptor);
      logger.finest('  -> $optionDescriptor');
    }

    return GetAllOptionDescriptorsResponse(optionDescriptors);
  }
}
