import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class OpenQuery implements Query<OpenResponse> {
  const OpenQuery(this.deviceName);
  final String deviceName;
}

class OpenResponse implements Response {
  const OpenResponse(this.handle);
  final SANEHandle handle;
}

class OpenQueryHandler
    extends QueryHandler<OpenQuery, OpenResponse, SANEBusContext> {
  const OpenQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  OpenResponse handle(OpenQuery query, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeHandlePointer = ffi.calloc<SANE_Handle>();
    final deviceNamePointer = query.deviceName.toSANEString();
    late final SANEHandle handle;

    try {
      final status = libsane.sane_open(deviceNamePointer, nativeHandlePointer);
      logger.finest('sane_open(${query.deviceName}) -> ${status.name}');

      status.check();

      handle = context.nativeHandles.createSANEHandle(
        nativeHandlePointer.value,
        query.deviceName,
      );
    } finally {
      ffi.calloc.free(nativeHandlePointer);
      ffi.calloc.free(deviceNamePointer);
    }

    return OpenResponse(handle);
  }
}
