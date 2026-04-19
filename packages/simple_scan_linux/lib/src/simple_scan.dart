import 'package:libsane/libsane.dart';
import 'package:logging/logging.dart';
import 'package:simple_scan_linux/simple_scan_linux.dart';
import 'package:simple_scan_linux/src/queries/cancel.dart';
import 'package:simple_scan_linux/src/queries/close.dart';
import 'package:simple_scan_linux/src/queries/exit.dart';
import 'package:simple_scan_linux/src/queries/init.dart';
import 'package:simple_scan_linux/src/queries/list_devices.dart';
import 'package:simple_scan_linux/src/queries/open_session.dart';
import 'package:simple_scan_linux/src/queries/scan.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

final class SimpleScanLinux extends SimpleScanPlatform {
  factory SimpleScanLinux() => _instance ??= SimpleScanLinux._();
  SimpleScanLinux._();
  static SimpleScanLinux? _instance;

  QueryBusIsolate? _isolatedBus;

  static void registerWith() {
    SimpleScanPlatform.instance = SimpleScanLinux();
  }

  Future<void> init() async {
    await _initBus();
    await _handle(InitQuery());
  }

  Future<void> dispose() async {
    await _handle(ExitQuery());
    await _isolatedBus!.exit();
    _isolatedBus = null;
  }

  Future<List<ScanDevice>> listDevices() async {
    final response = await _handle(ListDevicesQuery());
    return response.devices;
  }

  Future<ScanSession> openSession(String deviceId) async {
    final response = await _handle(OpenSessionQuery(deviceName: deviceId));

    // TODO error handling

    return ScanSessionLinux(
      isolatedBus: _isolatedBus!,
      handle: response.handle,
    );
  }

  Future<void> _initBus() async {
    if (_isolatedBus != null) {
      return;
    }

    _isolatedBus = await QueryBusIsolate.spawn(
      () {
        final sane = new SANESync();
        return QueryBus(
          handlers: [
            InitQueryHandler(sane),
            ExitQueryHandler(sane),
            ListDevicesQueryHandler(sane),
            OpenSessionQueryHandler(sane),
            ScanQueryHandler(sane),
            CancelQueryHandler(sane),
            CloseQueryHandler(sane),
          ],
          contextBuilder: SimpleScanBusContext.new,
        );
      },
      Logger('simple_scan.isolate'),
    );
  }

  Future<T> _handle<T extends Response>(
    Query<T> query,
  ) async {
    if (_isolatedBus == null) {
      throw StateError(
        'The isolated query bus has not been initialized, please call _initBus() first.',
      );
    }
    return await _isolatedBus!.handle(query);
  }
}

class SimpleScanBusContext extends BusContext {}
