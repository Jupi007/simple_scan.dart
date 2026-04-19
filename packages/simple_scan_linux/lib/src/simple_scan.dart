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
import 'package:meta/meta.dart';

final class SimpleScanLinux extends SimpleScanPlatform {
  SimpleScanLinux();

  @visibleForTesting
  QueryBusIsolate? isolatedBus;

  static void registerWith() {
    SimpleScanPlatform.instance = SimpleScanLinux();
  }

  Future<void> init() async {
    await _initBus();
    await _handle(InitQuery());
  }

  Future<void> dispose() async {
    await _handle(ExitQuery());
    await isolatedBus!.exit();
    isolatedBus = null;
  }

  Future<List<ScanDevice>> listDevices() async {
    final response = await _handle(ListDevicesQuery());
    return response.devices;
  }

  Future<ScanSession> openSession(String deviceId) async {
    final response = await _handle(OpenSessionQuery(deviceName: deviceId));

    // TODO error handling

    return ScanSessionLinux(
      isolatedBus: isolatedBus!,
      handle: response.handle,
    );
  }

  Future<void> _initBus() async {
    if (isolatedBus != null) {
      return;
    }

    isolatedBus = await QueryBusIsolate.spawn(
      () {
        final sane = new SANE();
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
    if (isolatedBus == null) {
      throw StateError(
        'The isolated query bus has not been initialized, please call _initBus() first.',
      );
    }
    return await isolatedBus!.handle(query);
  }
}

class SimpleScanBusContext extends BusContext {}
