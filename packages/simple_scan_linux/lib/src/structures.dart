import 'dart:typed_data';

import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/constants.dart';
import 'package:simple_scan_linux/src/extensions.dart';

abstract class ScanBuffer {
  int get width;
  int get height;
  void appendBytes(Uint8List bytes, SANEFrameFormat frameFormat);
  Uint8List toBytes();
}

class FixedScanBuffer extends ScanBuffer {
  FixedScanBuffer({
    required this.width,
    required this.height,
  }) : _bytes = Uint8List(width * 3 * height)
          ..fillRange(0, width * 3 * height, 0xFF);

  final int width;
  final int height;

  final Uint8List _bytes;

  @override
  Uint8List toBytes() => _bytes;

  int _offsetInFrame = 0;
  SANEFrameFormat? _previousFrameFormat;

  @override
  void appendBytes(Uint8List bytes, SANEFrameFormat frameFormat) {
    if (_previousFrameFormat != frameFormat) {
      _offsetInFrame = 0;
      _previousFrameFormat = frameFormat;
    }

    switch (frameFormat) {
      case SANEFrameFormat.rgb:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i;
          _bytes[pixelIndex] = bytes[i];
        }
        _offsetInFrame += bytes.length;
        break;
      case SANEFrameFormat.gray:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i * 3;
          _bytes[pixelIndex + RED_BYTE_INDEX] = bytes[i];
          _bytes[pixelIndex + GREEN_BYTE_INDEX] = bytes[i];
          _bytes[pixelIndex + BLUE_BYTE_INDEX] = bytes[i];
        }
        _offsetInFrame += bytes.length * 3;
        break;
      case SANEFrameFormat.red:
      case SANEFrameFormat.green:
      case SANEFrameFormat.blue:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i * 3;
          final rgbIndex = frameFormat.toRGBIndex();
          _bytes[pixelIndex + rgbIndex] = bytes[i];
        }
        _offsetInFrame += bytes.length * 3;
        break;
    }
  }
}

class HandScanBuffer extends ScanBuffer {
  HandScanBuffer({
    required this.width,
  });

  final int width;
  int get height => _linesBytes.length;
  final List<Uint8List> _linesBytes = <Uint8List>[];

  @override
  Uint8List toBytes() {
    final buffer = Uint8List(width * 3 * _linesBytes.length);
    var offset = 0;
    for (final lineBytes in _linesBytes) {
      buffer.setRange(offset, offset + lineBytes.length, lineBytes);
      offset += lineBytes.length;
    }
    return buffer;
  }

  int _offsetInFrame = 0;
  SANEFrameFormat? _previousFrameFormat;

  @override
  void appendBytes(Uint8List bytes, SANEFrameFormat frameFormat) {
    if (_previousFrameFormat != frameFormat) {
      _offsetInFrame = 0;
      _previousFrameFormat = frameFormat;
    }
    switch (frameFormat) {
      case SANEFrameFormat.rgb:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i;
          final linePixelIndex = _getLineOffsetAtOffset(pixelIndex);
          final buffer = _getLineBufferAtOffset(pixelIndex);
          buffer[linePixelIndex] = bytes[i];
        }
        _offsetInFrame += bytes.length;
        break;
      case SANEFrameFormat.gray:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i * 3;
          final linePixelIndex = _getLineOffsetAtOffset(pixelIndex);
          final buffer = _getLineBufferAtOffset(pixelIndex);
          buffer[linePixelIndex + RED_BYTE_INDEX] = bytes[i];
          buffer[linePixelIndex + GREEN_BYTE_INDEX] = bytes[i];
          buffer[linePixelIndex + BLUE_BYTE_INDEX] = bytes[i];
        }
        _offsetInFrame += bytes.length * 3;
        break;
      case SANEFrameFormat.red:
      case SANEFrameFormat.green:
      case SANEFrameFormat.blue:
        for (var i = 0; i < bytes.length; i++) {
          final pixelIndex = _offsetInFrame + i * 3;
          final rgbIndex = frameFormat.toRGBIndex();
          final linePixelIndex = _getLineOffsetAtOffset(pixelIndex);
          final buffer = _getLineBufferAtOffset(pixelIndex);
          buffer[linePixelIndex + rgbIndex] = bytes[i];
        }
        _offsetInFrame += bytes.length * 3;
        break;
    }
  }

  int get _bytesPerLine => width * 3;

  int _getLineOffsetAtOffset(int offset) {
    return offset % _bytesPerLine;
  }

  Uint8List _getLineBufferAtOffset(int offset) {
    final lineIndex = offset ~/ _bytesPerLine;
    if (_linesBytes.elementAtOrNull(lineIndex) == null) {
      _linesBytes.insert(
        lineIndex,
        Uint8List(_bytesPerLine)..fillRange(0, _bytesPerLine, 0xFF),
      );
    }
    return _linesBytes[lineIndex];
  }
}
