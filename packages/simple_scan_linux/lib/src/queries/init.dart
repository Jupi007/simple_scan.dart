import 'package:libsane/src/sane.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class InitQuery implements Query<InitResponse> {
  const InitQuery();
}

class InitResponse implements Response {
  const InitResponse();
}

class InitQueryHandler
    extends QueryHandler<InitQuery, InitResponse, SimpleScanBusContext> {
  const InitQueryHandler(this.sane);
  final SANE sane;

  @override
  InitResponse handle(InitQuery query, SimpleScanBusContext context) {
    sane.init();
    return InitResponse();
  }
}
