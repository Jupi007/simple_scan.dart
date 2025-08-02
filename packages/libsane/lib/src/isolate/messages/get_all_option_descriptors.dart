import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class GetAllOptionDescriptorsMessage
    implements IsolateMessage<GetAllOptionDescriptorsResponse> {
  const GetAllOptionDescriptorsMessage(this.handle);
  final SaneHandle handle;
}

class GetAllOptionDescriptorsResponse implements IsolateResponse {
  const GetAllOptionDescriptorsResponse(this.optionDescriptors);
  final List<SaneOptionDescriptor> optionDescriptors;
}

class GetAllOptionDescriptorsMessageHandler
    implements
        IsolateMessageHandler<GetAllOptionDescriptorsMessage,
            GetAllOptionDescriptorsResponse> {
  const GetAllOptionDescriptorsMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  GetAllOptionDescriptorsResponse handle(
    GetAllOptionDescriptorsMessage message,
    SaneIsolateContext context,
  ) {
    final optionDescriptors = <SaneOptionDescriptor>[];

    for (var i = 0;; i++) {
      final optionDescriptorPointer = libSane.sane_get_option_descriptor(
        context.nativeHandles.get(message.handle),
        i,
      );
      isolateLogger.finest('sane_get_option_descriptor()');

      if (optionDescriptorPointer == ffi.nullptr) break;
      optionDescriptors.add(
        optionDescriptorPointer.ref.toSaneOptionDescriptorWithIndex(i),
      );
    }

    return GetAllOptionDescriptorsResponse(optionDescriptors);
  }
}
