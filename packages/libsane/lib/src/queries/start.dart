import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class StartQuery implements Query<StartResponse> {
  const StartQuery(this.handle);
  final SANEHandle handle;
}

class StartResponse implements Response {
  const StartResponse();
}

class StartQueryHandler
    extends QueryHandler<StartQuery, StartResponse, SANEBusContext> {
  const StartQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  StartResponse handle(
    StartQuery query,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final status = libsane.sane_start(
      context.nativeHandles.get(query.handle),
    );
    logger.finest('sane_start() -> ${status.name}');

    status.check();

    return const StartResponse();
  }
}
