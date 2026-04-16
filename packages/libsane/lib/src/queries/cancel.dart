import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class CancelQuery implements Query<CancelResponse> {
  const CancelQuery(this.handle);
  final SANEHandle handle;
}

class CancelResponse implements Response {
  const CancelResponse();
}

class CancelQueryHandler
    extends QueryHandler<CancelQuery, CancelResponse, SANEBusContext> {
  const CancelQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  CancelResponse handle(CancelQuery query, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    libsane.sane_cancel(
      context.nativeHandles.get(query.handle),
    );
    logger.finest('sane_cancel()');

    return const CancelResponse();
  }
}
