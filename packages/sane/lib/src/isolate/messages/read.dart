import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/logger.dart';

class ReadMessage implements IsolateMessage<ReadResponse> {
  const ReadMessage(this.handle, this.bufferSize);
  final SaneHandle handle;
  final int bufferSize;
}

class ReadResponse implements IsolateResponse {
  const ReadResponse(this.bytes);
  final Uint8List bytes;
}

class ReadMessageHandler
    implements IsolateMessageHandler<ReadMessage, ReadResponse> {
  const ReadMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  ReadResponse handle(ReadMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    if (message.bufferSize <= 0) {
      throw ArgumentError(
        'Invalid bufferSize "$message.bufferSize" value, should be greater than 0.',
      );
    }

    final lengthPointer = ffi.calloc<SANE_Int>();
    final bufferPointer = ffi.calloc<SANE_Byte>(message.bufferSize);

    try {
      final status = libSane.sane_read(
        context.nativeHandles.get(message.handle),
        bufferPointer,
        message.bufferSize,
        lengthPointer,
      );
      isolateLogger.finest('sane_read() -> ${status.name}');

      try {
        status.check();
      } on SaneEofException catch (_) {
        return ReadResponse(Uint8List.fromList([]));
      }

      return ReadResponse(
        Uint8List.fromList(
          bufferPointer.cast<ffi.Uint8>().asTypedList(lengthPointer.value),
        ),
      );
    } finally {
      ffi.calloc.free(lengthPointer);
      ffi.calloc.free(bufferPointer);
    }
  }
}
