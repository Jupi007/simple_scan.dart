import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class ExitQuery implements Query<ExitResponse> {
  const ExitQuery();
}

class ExitResponse implements Response {
  const ExitResponse();
}

class ExitQueryHandler
    extends QueryHandler<ExitQuery, ExitResponse, SANEBusContext> {
  const ExitQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  ExitResponse handle(ExitQuery query, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    context.initialized = false;
    libsane.sane_exit();
    logger.finest('sane_exit()');

    context.nativeHandles.clear();
    context.nativeAuthCallback?.close();
    context.nativeAuthCallback = null;

    return const ExitResponse();
  }
}
