import 'package:libsane/libsane.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

import 'extensions.dart';
import 'scan_session.dart';

final class SimpleScanLinux extends SimpleScanPlatform {
  SimpleScanLinux(this.sane);

  final SANE sane;

  static void registerWith() {
    SimpleScanPlatform.instance = SimpleScanLinux(SANE.isolated());
  }

  Future<void> init() async => await sane.init();

  Future<void> dispose() async => await sane.exit();

  Future<List<ScanDevice>> listDevices() async {
    final saneDevices = await sane.getDevices(localOnly: true);
    return saneDevices.toScanDeviceList();
  }

  Future<ScanSession> openSession(String deviceId) async {
    final saneHandle = await sane.open(deviceId);

    // TODO error handling

    return ScanSessionLinux(
      sane: sane,
      handle: saneHandle,
    );
  }
}
