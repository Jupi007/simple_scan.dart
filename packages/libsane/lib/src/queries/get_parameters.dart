import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class GetParametersQuery implements Query<GetParametersResponse> {
  const GetParametersQuery(this.handle);
  final SANEHandle handle;
}

class GetParametersResponse implements Response {
  const GetParametersResponse(this.parameters);
  final SANEParameters parameters;
}

class GetParametersQueryHandler extends QueryHandler<GetParametersQuery,
    GetParametersResponse, SANEBusContext> {
  const GetParametersQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetParametersResponse handle(
    GetParametersQuery query,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeParametersPointer = ffi.calloc<SANE_Parameters>();

    try {
      final status = libsane.sane_get_parameters(
        context.nativeHandles.get(query.handle),
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');
      status.check();

      final parameters = nativeParametersPointer.ref.toSANEParameters();
      logger.finest('  -> $parameters');

      return GetParametersResponse(parameters);
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }
}
