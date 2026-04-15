import 'package:libsane/libsane.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

import 'constants.dart';

extension SANEDeviceListX on List<SANEDevice> {
  List<ScanDevice> toScanDeviceList() {
    final devices = <ScanDevice>[];
    for (final saneDevice in this) {
      devices.add(
        ScanDevice(
          id: saneDevice.name,
          model: saneDevice.model,
          vendor: saneDevice.vendor,
          type: saneDevice.type,
        ),
      );
    }
    return List.unmodifiable(devices);
  }
}

extension SANEFrameFormatX on SANEFrameFormat {
  int toRGBIndex() {
    switch (this) {
      case SANEFrameFormat.red:
        return RED_BYTE_INDEX;
      case SANEFrameFormat.green:
        return GREEN_BYTE_INDEX;
      case SANEFrameFormat.blue:
        return BLUE_BYTE_INDEX;
      default:
        throw UnsupportedError(
          'Frame RGB index is not supported for this frame format.',
        );
    }
  }
}

extension SANEOptionsDescriptorsListX on List<SANEOptionDescriptor> {
  SANEOptionDescriptor? get(String name) {
    for (final element in this) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }
}

extension IntX on int {
  int min(int min) => this < min ? min : this;
}
