import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class CloseQuery implements Query<CloseResponse> {
  const CloseQuery(this.handle);
  final SANEHandle handle;
}

class CloseResponse implements Response {
  const CloseResponse();
}

class CloseQueryHandler
    extends QueryHandler<CloseQuery, CloseResponse, SANEBusContext> {
  const CloseQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  CloseResponse handle(CloseQuery query, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    logger.finest('sane_close()');
    libsane.sane_close(context.nativeHandles.get(query.handle));

    context.nativeHandles.remove(query.handle);

    return const CloseResponse();
  }
}
