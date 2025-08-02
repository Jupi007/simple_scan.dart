import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';

class OpenMessage implements IsolateMessage<OpenResponse> {
  const OpenMessage(this.deviceName);
  final String deviceName;
}

class OpenResponse implements IsolateResponse {
  const OpenResponse(this.handle);
  final SaneHandle handle;
}

class OpenMessageHandler
    implements IsolateMessageHandler<OpenMessage, OpenResponse> {
  const OpenMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  OpenResponse handle(OpenMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    final nativeHandlePointer = ffi.calloc<SANE_Handle>();
    final deviceNamePointer = message.deviceName.toSaneString();
    late final SaneHandle handle;

    try {
      final status = libSane.sane_open(deviceNamePointer, nativeHandlePointer);
      isolateLogger.finest('sane_open() -> ${status.name}');

      status.check();

      handle = context.nativeHandles.createSaneHandle(
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
