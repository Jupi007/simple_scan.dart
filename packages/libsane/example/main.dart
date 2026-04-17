// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:libsane/libsane.dart';
import 'package:libsane/libsaneopts.dart' as saneopts;
import 'package:logging/logging.dart';

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final sane = SANE();

  sane.init();

  final devices = sane.getDevices(localOnly: true);
  for (final device in devices) {
    print('Device found: ${device.name}');
  }
  if (devices.isEmpty) {
    print('No device found');
    return;
  }

  final device = devices[1];
  final handle = sane.openDevice(device);

  final optionDescriptors = sane.getAllOptionDescriptors(handle);

  for (final optionDescriptor in optionDescriptors) {
    if (optionDescriptor.name == saneopts.NAME_SCAN_MODE) {
      sane.controlStringOption(
        handle: handle,
        index: optionDescriptor.index,
        action: SANEControlAction.setValue,
        value: saneopts.VALUE_SCAN_MODE_COLOR,
      );
      break;
    }
  }

  sane.start(handle);

  final parameters = sane.getParameters(handle);
  print('Parameters: format(${parameters.format}), depth(${parameters.depth})');

  final bytesBuilder = BytesBuilder(copy: false);
  while (true) {
    final bytes = sane.read(handle, parameters.bytesPerLine);
    if (bytes.isEmpty) break;
    bytesBuilder.add(bytes);
  }

  sane.cancel(handle);
  sane.close(handle);

  sane.exit();

  final file = File('./output.ppm');
  file.writeAsStringSync(
    'P6\n${parameters.pixelsPerLine} ${parameters.lines}\n255\n',
    mode: FileMode.write,
  );
  file.writeAsBytesSync(bytesBuilder.takeBytes(), mode: FileMode.append);
}
