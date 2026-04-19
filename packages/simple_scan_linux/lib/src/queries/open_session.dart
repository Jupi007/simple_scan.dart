import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class OpenSessionQuery implements Query<OpenSessionResponse> {
  const OpenSessionQuery({
    required this.deviceName,
  });
  final String deviceName;
}

class OpenSessionResponse implements Response {
  const OpenSessionResponse(
    this.handle,
  );
  final SANEHandle handle;
}

class OpenSessionQueryHandler extends QueryHandler<OpenSessionQuery,
    OpenSessionResponse, SimpleScanBusContext> {
  const OpenSessionQueryHandler(this.sane);
  final SANESync sane;

  @override
  OpenSessionResponse handle(
      OpenSessionQuery query, SimpleScanBusContext context) {
    return OpenSessionResponse(
      sane.open(query.deviceName),
    );
  }
}
