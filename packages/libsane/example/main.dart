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

  await sane.init();

  final devices = await sane.getDevices(localOnly: true);
  if (devices.isEmpty) {
    print('No device found');
    return;
  }

  final device = devices[1];
  final handle = await sane.openDevice(device);

  final optionDescriptors = await sane.getAllOptionDescriptors(handle);

  for (final optionDescriptor in optionDescriptors) {
    if (optionDescriptor.name == saneopts.NAME_SCAN_MODE) {
      await sane.controlStringOption(
        handle: handle,
        index: optionDescriptor.index,
        action: SANEControlAction.setValue,
        value: saneopts.VALUE_SCAN_MODE_COLOR,
      );
      break;
    }
  }

  await sane.start(handle);

  final parameters = await sane.getParameters(handle);
  print('Parameters: format(${parameters.format}), depth(${parameters.depth})');

  final bytesBuilder = BytesBuilder(copy: false);
  while (true) {
    final bytes = await sane.read(handle, parameters.bytesPerLine);
    if (bytes.isEmpty) break;
    bytesBuilder.add(bytes);
  }

  // await sane.cancel(handle);
  await sane.close(handle);

  await sane.exit();

  final file = File('./output.ppm');
  file.writeAsStringSync(
    'P6\n${parameters.pixelsPerLine} ${parameters.lines}\n255\n',
    mode: FileMode.write,
  );
  file.writeAsBytesSync(bytesBuilder.takeBytes(), mode: FileMode.append);
}
