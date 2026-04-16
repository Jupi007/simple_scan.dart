// ignore_for_file: avoid_print

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:simple_scan/simple_scan.dart';
import 'package:simple_scan_linux/simple_scan_linux.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  SimpleScanLinux.registerWith();

  final simpleScan = SimpleScan();
  await simpleScan.init();
  final devices = await simpleScan.listDevices();
  final scanSession = await simpleScan.openSession(devices[1].id);

  final scanResult = await scanSession.scan(
    const ScanOptions(
      color: true,
      dpi: 100,
      pageSize: null,
    ),
  );

  await scanSession.close();
  await simpleScan.dispose();

  final file = File('./output.ppm');
  file.writeAsStringSync(
    'P6\n${scanResult.width} ${scanResult.height}\n255\n',
    mode: FileMode.write,
  );
  file.writeAsBytesSync(scanResult.bytes, mode: FileMode.append);
}
