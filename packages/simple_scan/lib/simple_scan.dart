import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

export 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

final class SimpleScan {
  Future<void> init() async {
    await SimpleScanPlatform.instance.init();
  }

  Future<void> dispose() async {
    await SimpleScanPlatform.instance.dispose();
  }

  Future<List<ScanDevice>> listDevices() async {
    return await SimpleScanPlatform.instance.listDevices();
  }

  Future<ScanSession> openSession(String deviceId) async {
    return await SimpleScanPlatform.instance.openSession(deviceId);
  }
}
