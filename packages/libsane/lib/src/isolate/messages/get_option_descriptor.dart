import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class GetOptionDescriptorMessage
    implements IsolateMessage<GetOptionDescriptorResponse> {
  const GetOptionDescriptorMessage(this.handle, this.index);
  final SaneHandle handle;
  final int index;
}

class GetOptionDescriptorResponse implements IsolateResponse {
  const GetOptionDescriptorResponse(this.optionDescriptor);
  final SaneOptionDescriptor? optionDescriptor;
}

class GetOptionDescriptorMessageHandler
    implements
        IsolateMessageHandler<GetOptionDescriptorMessage,
            GetOptionDescriptorResponse> {
  const GetOptionDescriptorMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  GetOptionDescriptorResponse handle(
    GetOptionDescriptorMessage message,
    SaneIsolateContext context,
  ) {
    if (!context.initialized) throw SaneNotInitializedError();

    final optionDescriptorPointer = libSane.sane_get_option_descriptor(
      context.nativeHandles.get(message.handle),
      message.index,
    );
    isolateLogger.finest('sane_close()');

    if (optionDescriptorPointer == ffi.nullptr) {
      return const GetOptionDescriptorResponse(null);
    }

    return GetOptionDescriptorResponse(
      optionDescriptorPointer.ref
          .toSaneOptionDescriptorWithIndex(message.index),
    );
  }
}
