import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class CancelQuery implements Query<CancelResponse> {
  const CancelQuery(this.handle);
  final SANEHandle handle;
}

class CancelResponse implements Response {
  const CancelResponse();
}

class CancelQueryHandler
    extends QueryHandler<CancelQuery, CancelResponse, SimpleScanBusContext> {
  const CancelQueryHandler(this.sane);
  final SANE sane;

  @override
  CancelResponse handle(CancelQuery query, SimpleScanBusContext context) {
    sane.cancel(query.handle);
    return CancelResponse();
  }
}
