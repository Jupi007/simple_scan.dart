import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/logger.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage<GetParametersResponse> {
  const GetParametersMessage(this.handle);
  final SaneHandle handle;
}

class GetParametersResponse implements IsolateResponse {
  const GetParametersResponse(this.parameters);
  final SaneParameters parameters;
}

class GetParametersMessageHandler
    implements
        IsolateMessageHandler<GetParametersMessage, GetParametersResponse> {
  const GetParametersMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  GetParametersResponse handle(
    GetParametersMessage message,
    SaneIsolateContext context,
  ) {
    if (!context.initialized) throw SaneNotInitializedError();

    final nativeParametersPointer = ffi.calloc<SANE_Parameters>();

    try {
      final status = libSane.sane_get_parameters(
        context.nativeHandles.get(message.handle),
        nativeParametersPointer,
      );
      isolateLogger.finest('sane_get_parameters() -> ${status.name}');

      status.check();

      return GetParametersResponse(
        nativeParametersPointer.ref.toSaneParameters(),
      );
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }
}
