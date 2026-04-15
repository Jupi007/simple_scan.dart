import 'dart:typed_data';

import 'package:libsane/libsane.dart';
import 'package:libsane/libsaneopts.dart' as saneopts;
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';

import 'constants.dart';
import 'extensions.dart';
import 'structures.dart';

final class ScanSessionLinux extends ScanSession {
  ScanSessionLinux({
    required this.sane,
    required this.handle,
  });

  final SANE sane;
  final SANEHandle handle;

  bool _closed = false;

  Stream<ScanSnapshot> scan(ScanOptions options) async* {
    _checkIfClosed();

    await _applyOptions(options);

    var lastFrame = false;
    ScanBuffer? scanBuffer;

    outerLoop:
    do {
      await sane.start(handle);

      final parameters = await sane.getParameters(handle);
      if (scanBuffer == null) {
        if (parameters.lines == -1) {
          scanBuffer = HandScanBuffer(width: parameters.pixelsPerLine);
        } else {
          scanBuffer = FixedScanBuffer(
            width: parameters.pixelsPerLine,
            height: parameters.lines,
          );
        }
      }
      lastFrame = parameters.lastFrame;

      if (parameters.depth != 8) {
        // TODO support different bit depth
        throw Exception('Imcompatible depth');
      }

      while (true) {
        late final Uint8List readBytes;
        try {
          readBytes = await sane.read(handle, parameters.bytesPerLine);
          if (readBytes.isEmpty) break;
        } on SANECancelledException catch (_) {
          break outerLoop;
        }
        final updatedLines =
            scanBuffer.appendBytes(readBytes, parameters.format);

        yield LinuxScanSnapshot(
          buffer: scanBuffer,
          updatedLinesStart: updatedLines.start,
          updatedLinesEnd: updatedLines.end,
        );
      }
    } while (!lastFrame);

    await sane.cancel(handle);
  }

  Future<void> _applyOptions(ScanOptions options) async {
    final optionDescriptors = await sane.getAllOptionDescriptors(handle);

    await _applyColorOption(options, optionDescriptors);
    await _applyDpiOption(options, optionDescriptors);
    await _applyDepthOption(options, optionDescriptors);
    await _applyPageSizeOption(options, optionDescriptors);
    await _applyBrightnessContrastOptions(options, optionDescriptors);
  }

  Future<void> _applyColorOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
  ) async {
    // Copied from GNOME simple-scan - scanner.vala L1054-1060
    final colorScanMode = [
      saneopts.VALUE_SCAN_MODE_COLOR,
      'Color',
      '24bit Color[Fast]', // brother4 driver, Brother DCP-1622WE
      '24bit Color', // Seen in the proprietary brother3 driver
      '24-bit Color', // Lexmark CX310dn
      '24 bit Color', // brscanads2200ads2700w
      'Color - 16 Million Colors', // Samsung unified driver.
    ];
    // Copied from GNOME simple-scan - scanner.vala L1044-1070
    final grayScanMode = [
      saneopts.VALUE_SCAN_MODE_GRAY,
      'Gray',
      'Grayscale',
      '8-bit Grayscale', // Lexmark CX310dn
      'True Gray', // Seen in the proprietary brother3 driver
      'Grayscale - 256 Levels', // Samsung unified driver
    ];

    final optionDescriptor = optionDescriptors.get(saneopts.NAME_SCAN_MODE);
    if (optionDescriptor == null) return;
    await _controlStringConstrainedOption(
      options.color ? colorScanMode : grayScanMode,
      optionDescriptor,
    );
  }

  Future<void> _applyDpiOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
  ) async {
    final dpiOptionNames = [
      saneopts.NAME_SCAN_X_RESOLUTION,
      saneopts.NAME_SCAN_Y_RESOLUTION,
      saneopts.NAME_SCAN_RESOLUTION,
      'scan-resolution', // Lexmark CX310dn Duplex
    ];

    for (final name in dpiOptionNames) {
      final optionDescriptor = optionDescriptors.get(name);
      if (optionDescriptor == null) continue;
      await _controlIntOrFixedOption(
        options.dpi.toDouble(),
        optionDescriptor,
      );
    }
  }

  Future<void> _applyDepthOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
  ) async {
    final optionDescriptor = optionDescriptors.get(saneopts.NAME_BIT_DEPTH);
    if (optionDescriptor == null) return;
    // TODO Support more bit depth
    await _controlIntOrFixedOption(8, optionDescriptor);
  }

  Future<void> _applyPageSizeOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
  ) async {
    Map.from({
      saneopts.NAME_SCAN_BR_X: options.pageSize?.width,
      saneopts.NAME_SCAN_BR_Y: options.pageSize?.height,
      saneopts.NAME_PAGE_WIDTH: options.pageSize?.width,
      saneopts.NAME_PAGE_HEIGHT: options.pageSize?.height,
    }).forEach(
      (key, value) async {
        final optionDescriptor = optionDescriptors.get(key);
        if (optionDescriptor == null) return;

        if (value != null) {
          await _controlIntOrFixedOption(
            _convertPageSize(optionDescriptor.unit, value, options.dpi),
            optionDescriptor,
          );
          return;
        }
      },
    );

    if (options.pageSize == null) {
      final scanAreaOptionDescriptor = optionDescriptors.get('scan-area');
      if (scanAreaOptionDescriptor == null) return;
      await sane.controlStringOption(
        handle: handle,
        index: scanAreaOptionDescriptor.index,
        action: SANEControlAction.setValue,
        value: 'Maximum',
      );

      final autoDocumentSizeOptionDescriptor =
          optionDescriptors.get('AutoDocumentSize');
      if (autoDocumentSizeOptionDescriptor == null) return;
      await sane.controlBoolOption(
        handle: handle,
        index: autoDocumentSizeOptionDescriptor.index,
        action: SANEControlAction.setValue,
        value: true,
      );
    }
  }

  Future<void> _applyBrightnessContrastOptions(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
  ) async {
    Map.from({
      saneopts.NAME_BRIGHTNESS: options.brightness,
      saneopts.NAME_CONTRAST: options.contrast,
    }).forEach(
      (key, value) async {
        final optionDescriptor = optionDescriptors.get(key);
        if (optionDescriptor == null) return;
        await _controlIntOrFixedOption(value, optionDescriptor);
      },
    );
  }

  Future<void> _controlStringConstrainedOption(
    List<String> values,
    SANEOptionDescriptor optionDescriptor,
  ) async {
    if (!optionDescriptor.capabilities
            .contains(SANEOptionCapability.softSelect) ||
        optionDescriptor.capabilities.contains(SANEOptionCapability.inactive)) {
      return;
    }

    if (optionDescriptor.constraint is! SANEOptionConstraintStringList) {
      throw SimpleScanError(
        'Unsupported option descriptor constraint type: ${optionDescriptor.constraint}',
      );
    }

    final constraint =
        optionDescriptor.constraint as SANEOptionConstraintStringList;
    for (final value in values) {
      if (!constraint.stringList.contains(value)) {
        continue;
      }
      await sane.controlStringOption(
        handle: handle,
        index: optionDescriptor.index,
        action: SANEControlAction.setValue,
        value: value,
      );
      break;
    }
  }

  Future<void> _controlIntOrFixedOption(
    num? value,
    SANEOptionDescriptor optionDescriptor,
  ) async {
    if (!optionDescriptor.capabilities
            .contains(SANEOptionCapability.softSelect) ||
        optionDescriptor.capabilities.contains(SANEOptionCapability.inactive)) {
      return;
    }

    if (optionDescriptor.constraint is SANEOptionConstraintRange &&
        value != null) {
      final constraint =
          optionDescriptor.constraint as SANEOptionConstraintRange;
      final quantization = constraint.quant;

      value.clamp(constraint.min, constraint.max);
      if (quantization > 0) {
        final steps = (value / quantization).round();
        value = quantization * steps;
      }
    }

    if (optionDescriptor.constraint is SANEOptionConstraintWordList &&
        value != null) {
      final constraint =
          optionDescriptor.constraint as SANEOptionConstraintWordList;
      num? nearest;
      num? bestDistance;
      for (final word in constraint.wordList) {
        final distance = (word - value).abs();
        if (bestDistance == null || distance < bestDistance) {
          bestDistance = distance;
          nearest = word;
        }
      }
      value = nearest!;
    }

    switch (optionDescriptor.type) {
      case SANEOptionValueType.fixed:
        await sane.controlFixedOption(
          handle: handle,
          index: optionDescriptor.index,
          action: SANEControlAction.setValue,
          value: value?.toDouble(),
        );
        break;
      case SANEOptionValueType.int:
        await sane.controlIntOption(
          handle: handle,
          index: optionDescriptor.index,
          action: SANEControlAction.setValue,
          value: value?.toInt(),
        );
        break;
      default:
        throw SimpleScanError(
          'Unsupported option descriptor type: ${optionDescriptor.type}',
        );
    }
  }

  double _convertPageSize(SANEOptionUnit unit, double size, int dpi) {
    switch (unit) {
      case SANEOptionUnit.mm:
        return size;
      case SANEOptionUnit.pixel:
        return size * MM_INCH_RATIO;
      default:
        throw SimpleScanError(
          'Unsupported SANEOptionUnit: $unit',
        );
    }
  }

  Future<void> cancel() async {
    _checkIfClosed();
    await sane.cancel(handle);
  }

  Future<void> close() async {
    _checkIfClosed();
    _closed = true;
    await sane.close(handle);
  }

  void _checkIfClosed() {
    if (_closed) {
      throw StateError('This scan session is closed, please open a new one.');
    }
  }
}
