import 'dart:typed_data';

import 'package:libsane/libsane.dart';
import 'package:simple_scan_linux/src/constants.dart';
import 'package:simple_scan_linux/src/extensions.dart';
import 'package:simple_scan_linux/src/simple_scan.dart';
import 'package:simple_scan_linux/src/structures.dart';
import 'package:simple_scan_platform_interface/simple_scan_platform_interface.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';
import 'package:libsane/libsaneopts.dart' as saneopts;

class ScanQuery implements Query<ScanResponse> {
  const ScanQuery(this.handle, this.options);
  final SANEHandle handle;
  final ScanOptions options;
}

class ScanResponse implements Response {
  const ScanResponse(this.page);
  final ScanPage page;
}

class ScanQueryHandler
    extends QueryHandler<ScanQuery, ScanResponse, SimpleScanBusContext> {
  const ScanQueryHandler(this.sane);
  final SANE sane;

  @override
  ScanResponse handle(ScanQuery query, SimpleScanBusContext context) {
    _applyOptions(query);

    var lastFrame = false;
    ScanBuffer? scanBuffer;

    frameLoop:
    do {
      sane.start(query.handle);

      final parameters = sane.getParameters(query.handle);
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
          readBytes = sane.read(query.handle, parameters.bytesPerLine);
          if (readBytes.isEmpty) break;
        } on SANECancelledException catch (_) {
          break frameLoop;
        }

        scanBuffer.appendBytes(readBytes, parameters.format);
      }
    } while (!lastFrame);

    sane.cancel(query.handle);

    return ScanResponse(scanBuffer.toScanPage());
  }

  void _applyOptions(ScanQuery query) {
    final optionDescriptors = sane.getAllOptionDescriptors(query.handle);

    _applyColorOption(query.options, optionDescriptors, query.handle);
    _applyDpiOption(query.options, optionDescriptors, query.handle);
    _applyDepthOption(query.options, optionDescriptors, query.handle);
    _applyPageSizeOption(query.options, optionDescriptors, query.handle);
    _applyBrightnessContrastOptions(
        query.options, optionDescriptors, query.handle);
  }

  void _applyColorOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
    SANEHandle handle,
  ) {
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
    _controlStringConstrainedOption(
      options.color ? colorScanMode : grayScanMode,
      optionDescriptor,
      handle,
    );
  }

  void _applyDpiOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
    SANEHandle handle,
  ) {
    final dpiOptionNames = [
      saneopts.NAME_SCAN_X_RESOLUTION,
      saneopts.NAME_SCAN_Y_RESOLUTION,
      saneopts.NAME_SCAN_RESOLUTION,
      'scan-resolution', // Lexmark CX310dn Duplex
    ];

    for (final name in dpiOptionNames) {
      final optionDescriptor = optionDescriptors.get(name);
      if (optionDescriptor == null) continue;
      _controlIntOrFixedOption(
        options.dpi.toDouble(),
        optionDescriptor,
        handle,
      );
    }
  }

  void _applyDepthOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
    SANEHandle handle,
  ) {
    final optionDescriptor = optionDescriptors.get(saneopts.NAME_BIT_DEPTH);
    if (optionDescriptor == null) return;
    // TODO Support more bit depth
    _controlIntOrFixedOption(8, optionDescriptor, handle);
  }

  void _applyPageSizeOption(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
    SANEHandle handle,
  ) {
    Map.from({
      saneopts.NAME_SCAN_BR_X: options.pageSize?.width,
      saneopts.NAME_SCAN_BR_Y: options.pageSize?.height,
      saneopts.NAME_PAGE_WIDTH: options.pageSize?.width,
      saneopts.NAME_PAGE_HEIGHT: options.pageSize?.height,
    }).forEach(
      (key, value) {
        final optionDescriptor = optionDescriptors.get(key);
        if (optionDescriptor == null) return;

        if (value != null) {
          _controlIntOrFixedOption(
            _convertPageSize(optionDescriptor.unit, value, options.dpi),
            optionDescriptor,
            handle,
          );
          return;
        }
      },
    );

    if (options.pageSize == null) {
      final scanAreaOptionDescriptor = optionDescriptors.get('scan-area');
      if (scanAreaOptionDescriptor == null) return;
      sane.controlStringOption(
        handle: handle,
        index: scanAreaOptionDescriptor.index,
        action: SANEControlAction.setValue,
        value: 'Maximum',
      );

      final autoDocumentSizeOptionDescriptor =
          optionDescriptors.get('AutoDocumentSize');
      if (autoDocumentSizeOptionDescriptor == null) return;
      sane.controlBoolOption(
        handle: handle,
        index: autoDocumentSizeOptionDescriptor.index,
        action: SANEControlAction.setValue,
        value: true,
      );
    }
  }

  void _applyBrightnessContrastOptions(
    ScanOptions options,
    List<SANEOptionDescriptor> optionDescriptors,
    SANEHandle handle,
  ) {
    Map.from({
      saneopts.NAME_BRIGHTNESS: options.brightness,
      saneopts.NAME_CONTRAST: options.contrast,
    }).forEach(
      (key, value) {
        final optionDescriptor = optionDescriptors.get(key);
        if (optionDescriptor == null) return;
        _controlIntOrFixedOption(value, optionDescriptor, handle);
      },
    );
  }

  void _controlStringConstrainedOption(
    List<String> values,
    SANEOptionDescriptor optionDescriptor,
    SANEHandle handle,
  ) {
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
      sane.controlStringOption(
        handle: handle,
        index: optionDescriptor.index,
        action: SANEControlAction.setValue,
        value: value,
      );
      break;
    }
  }

  void _controlIntOrFixedOption(
    num? value,
    SANEOptionDescriptor optionDescriptor,
    SANEHandle handle,
  ) {
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
        sane.controlFixedOption(
          handle: handle,
          index: optionDescriptor.index,
          action: SANEControlAction.setValue,
          value: value?.toDouble(),
        );
        break;
      case SANEOptionValueType.int:
        sane.controlIntOption(
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
}
