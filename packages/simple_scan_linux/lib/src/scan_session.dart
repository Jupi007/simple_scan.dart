import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/queries/cancel.dart';
import 'package:simple_scan_linux/src/queries/close.dart';
import 'package:simple_scan_linux/src/queries/scan.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

final class ScanSessionLinux extends ScanSession {
  ScanSessionLinux({
    required this.isolatedBus,
    required this.handle,
  });

  final QueryBusIsolate isolatedBus;
  final SANEHandle handle;

  bool _closed = false;

  Future<ScanPage> scan(ScanOptions options) async {
    _checkIfClosed();
    final response = await isolatedBus.handle(ScanQuery(handle, options));
    return response.page;
  }

  Future<void> cancel() async {
    _checkIfClosed();
    await isolatedBus.handle(CancelQuery(handle));
  }

  Future<void> close() async {
    _checkIfClosed();
    _closed = true;
    await isolatedBus.handle(CloseQuery(handle));
  }

  void _checkIfClosed() {
    if (_closed) {
      throw StateError('This scan session is closed, please open a new one.');
    }
  }
}
