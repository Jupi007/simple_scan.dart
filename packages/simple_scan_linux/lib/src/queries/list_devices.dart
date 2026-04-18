import 'package:libsane/src/sane.dart';
import 'package:simple_scan_linux/src/extensions.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class ListDevicesQuery implements Query<ListDevicesResponse> {
  const ListDevicesQuery();
}

class ListDevicesResponse implements Response {
  const ListDevicesResponse(
    this.devices,
  );
  final List<ScanDevice> devices;
}

class ListDevicesQueryHandler extends QueryHandler<ListDevicesQuery,
    ListDevicesResponse, SimpleScanBusContext> {
  const ListDevicesQueryHandler(this.sane);
  final SANE sane;

  @override
  ListDevicesResponse handle(
      ListDevicesQuery query, SimpleScanBusContext context) {
    return ListDevicesResponse(
      sane.getDevices(localOnly: false).toScanDeviceList(),
    );
  }
}
