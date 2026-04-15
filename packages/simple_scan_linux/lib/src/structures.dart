import 'dart:typed_data';

import 'package:libsane/libsane.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

import 'constants.dart';
import 'extensions.dart';

class LinuxScanSnapshot implements ScanSnapshot {
  const LinuxScanSnapshot({
    required this.buffer,
    required this.updatedLinesStart,
    required this.updatedLinesEnd,
  });

  final ScanBuffer buffer;

  @override
  final int updatedLinesStart;

  @override
  final int updatedLinesEnd;

  Uint8List get fullPageBytes {
    return buffer.toBytes();
  }

  int get pageWidth => buffer.width;

  int get pageHeight => buffer.height;

  @override
  Uint8List get updatedBytesView =>
      buffer.linesView(updatedLinesStart, updatedLinesEnd);
}

class UpdatedLines {
  const UpdatedLines(
    this.start,
    this.end,
  );

  final int start;
  final int end;
}

abstract interface class ScanBuffer {
  int get width;
  int get height;
  UpdatedLines appendBytes(Uint8List bytes, SANEFrameFormat frameFormat);
  Uint8List toBytes();
  Uint8List linesView(int start, int end);
  // TODO Array access?
}

class FixedScanBuffer implements ScanBuffer {
  FixedScanBuffer({
    required this.width,
    required this.height,
  }) : _bytes = Uint8List(width * 3 * height)
          ..fillRange(0, width * 3 * height, 0xFF);

  final int width;
  final int height;

  final Uint8List _bytes;

  @override
  Uint8List linesView(int start, int end) {
    assert(start >= 0 && start < height);
    assert(end > 0 && end <= height);
    final viewStart = width * 3 * start;
    final viewEnd = width * 3 * end;
    return Uint8List.sublistView(_bytes, viewStart, viewEnd);
  }

  @override
  Uint8List toBytes() => _bytes;

  int _offsetInFrame = 0;
  SANEFrameFormat? _previousFrameFormat;

  @override
  UpdatedLines appendBytes(Uint8List bytes, SANEFrameFormat frameFormat) {
    if (_previousFrameFormat != frameFormat) {
      _offsetInFrame = 0;
      _previousFrameFormat = frameFormat;
    }
    final start = _offsetInFrame ~/ (width * 3);
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
    final end = (_offsetInFrame - 1) ~/ (width * 3);
    return UpdatedLines(start, end);
  }
}

class HandScanBuffer implements ScanBuffer {
  HandScanBuffer({
    required this.width,
  });

  final int width;
  int get height => _linesBytes.length;
  final List<Uint8List> _linesBytes = <Uint8List>[];

  @override
  Uint8List linesView(int start, int end) {
    if (start + 1 == end) {
      return _linesBytes[start];
    }

    final buffer = Uint8List(width * 3);
    var offset = 0;
    for (var i = start; i < end; i++) {
      final lineBytes = _linesBytes[i];
      buffer.setRange(offset, offset + lineBytes.length, lineBytes);
      offset += lineBytes.length;
    }
    return buffer;
  }

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
  UpdatedLines appendBytes(Uint8List bytes, SANEFrameFormat frameFormat) {
    if (_previousFrameFormat != frameFormat) {
      _offsetInFrame = 0;
      _previousFrameFormat = frameFormat;
    }
    final start = _offsetInFrame ~/ _bytesPerLine;
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
    final end = (_offsetInFrame - 1) ~/ _bytesPerLine;
    return UpdatedLines(start, end);
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
