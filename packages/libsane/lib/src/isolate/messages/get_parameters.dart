import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

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

      final parameters = nativeParametersPointer.ref.toSaneParameters();
      isolateLogger.finest('  -> $parameters');

      return GetParametersResponse(parameters);
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }
}
