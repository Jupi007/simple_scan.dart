import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class ExitQuery implements Query<ExitResponse> {
  const ExitQuery();
}

class ExitResponse implements Response {
  const ExitResponse();
}

class ExitQueryHandler
    extends QueryHandler<ExitQuery, ExitResponse, SimpleScanBusContext> {
  const ExitQueryHandler(this.sane);
  final SANESync sane;

  @override
  ExitResponse handle(ExitQuery query, SimpleScanBusContext context) {
    sane.exit();
    return ExitResponse();
  }
}
