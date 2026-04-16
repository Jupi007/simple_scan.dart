import 'dart:typed_data';

class ScanDevice {
  const ScanDevice({
    required this.id,
    required this.model,
    required this.vendor,
    required this.type,
  });

  final String id;
  final String model;
  final String vendor;
  final String type;
}

class ScanOptions {
  const ScanOptions({
    required this.dpi,
    required this.color,
    required this.pageSize,
    this.brightness = 0,
    this.contrast = 0,
  });

  final int dpi;
  final bool color;

  /// Target scan page size, set null for max value allowed by device
  final ScanOptionPageSize? pageSize;

  final int brightness;
  final int contrast;
}

class ScanOptionPageSize {
  /// Target scan page size, expressed in millimetres.
  const ScanOptionPageSize({
    required this.width,
    required this.height,
  });

  /// Target scan page width, expressed in millimetres.
  final double width;

  /// Target scan page height, expressed in millimetres.
  final double height;
}

class ScanPage {
  const ScanPage({
    required this.height,
    required this.width,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}
