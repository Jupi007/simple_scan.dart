import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class CloseQuery implements Query<CloseResponse> {
  const CloseQuery(this.handle);
  final SANEHandle handle;
}

class CloseResponse implements Response {
  const CloseResponse();
}

class CloseQueryHandler
    extends QueryHandler<CloseQuery, CloseResponse, SimpleScanBusContext> {
  const CloseQueryHandler(this.sane);
  final SANE sane;

  @override
  CloseResponse handle(CloseQuery query, SimpleScanBusContext context) {
    sane.close(query.handle);
    return CloseResponse();
  }
}
