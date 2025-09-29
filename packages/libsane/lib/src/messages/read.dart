import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';

final freePointer = ffi.DynamicLibrary.process()
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
  'free',
);

class _ReadMessage<R extends Response> implements Message<R> {
  const _ReadMessage(this.handle, this.bufferSize);
  final SANEHandle handle;
  final int bufferSize;
}

class SyncReadMessage extends _ReadMessage<SyncReadResponse> {
  const SyncReadMessage(super.handle, super.bufferSize);
}

class SyncReadResponse implements Response {
  const SyncReadResponse(this.bytes);
  final Uint8List bytes;
}

class SyncReadMessageHandler
    extends MessageHandler<SyncReadMessage, SyncReadResponse, SANEBusContext> {
  const SyncReadMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  SyncReadResponse handle(
    SyncReadMessage message,
    SANEBusContext context,
  ) {
    return SyncReadResponse(
      _read(libsane, context, message.handle, message.bufferSize),
    );
  }
}

class IsolateReadMessage extends _ReadMessage<IsolateReadResponse> {
  const IsolateReadMessage(super.handle, super.bufferSize);
}

class IsolateReadResponse implements Response {
  const IsolateReadResponse(this.bytes);
  final TransferableTypedData bytes;
}

class IsolateReadMessageHandler extends MessageHandler<IsolateReadMessage,
    IsolateReadResponse, SANEBusContext> {
  const IsolateReadMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  IsolateReadResponse handle(
    IsolateReadMessage message,
    SANEBusContext context,
  ) {
    return IsolateReadResponse(
      TransferableTypedData.fromList([
        _read(libsane, context, message.handle, message.bufferSize),
      ]),
    );
  }
}

Uint8List _read(
  LibSANE libsane,
  SANEBusContext context,
  SANEHandle handle,
  int bufferSize,
) {
  if (!context.initialized) throw SANENotInitializedError();

  if (bufferSize <= 0) {
    throw ArgumentError(
      'Invalid bufferSize "$bufferSize" value, should be greater than 0.',
    );
  }

  final lengthPointer = ffi.malloc<SANE_Int>();
  final bufferPointer = ffi.malloc<SANE_Byte>(bufferSize);

  try {
    final status = libsane.sane_read(
      context.nativeHandles.get(handle),
      bufferPointer,
      bufferSize,
      lengthPointer,
    );
    logger.finest('sane_read($bufferSize) -> ${status.name}');

    try {
      status.check();
    } on SANEEofException catch (_) {
      return Uint8List.fromList([]);
    }

    return bufferPointer
        .cast<ffi.Uint8>()
        .asTypedList(
          lengthPointer.value,
          finalizer: freePointer,
        )
        .asUnmodifiableView();
  } finally {
    ffi.malloc.free(lengthPointer);
  }
}
