import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

final freePointer = ffi.DynamicLibrary.process()
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
  'free',
);

class _ReadQuery<R extends Response> implements Query<R> {
  const _ReadQuery(this.handle, this.bufferSize);
  final SANEHandle handle;
  final int bufferSize;
}

class SyncReadQuery extends _ReadQuery<SyncReadResponse> {
  const SyncReadQuery(super.handle, super.bufferSize);
}

class SyncReadResponse implements Response {
  const SyncReadResponse(this.bytes);
  final Uint8List bytes;
}

class SyncReadQueryHandler
    extends QueryHandler<SyncReadQuery, SyncReadResponse, SANEBusContext> {
  const SyncReadQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  SyncReadResponse handle(
    SyncReadQuery query,
    SANEBusContext context,
  ) {
    return SyncReadResponse(
      _read(libsane, context, query.handle, query.bufferSize),
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
    logger.finest('sane_read($bufferSize)');
    final status = libsane.sane_read(
      context.nativeHandles.get(handle),
      bufferPointer,
      bufferSize,
      lengthPointer,
    );
    logger.finest('  -> ${status.name}');

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
