import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/structures.dart';
import 'package:logging/logging.dart';

extension LoggerExtension on Logger {
  void redirect(LogRecord record) {
    log(
      record.level,
      record.message,
      record.error,
      record.stackTrace,
      record.zone,
    );
  }
}

extension CheckNativeSANEStatusExtension on SANE_Status {
  /// Throws [SANEException] if the status is not [SANE_Status.STATUS_GOOD].
  void check() {
    if (this != SANE_Status.STATUS_GOOD) {
      throw SANEException(this);
    }
  }
}

extension NativeSANEDeviceExtension on SANE_Device {
  /// Convert native [SANE_Device] to [SANEDevice].
  SANEDevice toSANEDevice() {
    return SANEDevice(
      name: name.toDartString(),
      vendor: vendor.toDartString(),
      model: model.toDartString(),
      type: type.toDartString(),
    );
  }
}

extension NativeSANEFrameFormatExtension on SANE_Frame {
  /// Convert native [SANE_Frame] to [SANEFrameFormat].
  SANEFrameFormat toSANEFrameFormat() {
    return switch (this) {
      SANE_Frame.FRAME_GRAY => SANEFrameFormat.gray,
      SANE_Frame.FRAME_RGB => SANEFrameFormat.rgb,
      SANE_Frame.FRAME_RED => SANEFrameFormat.red,
      SANE_Frame.FRAME_GREEN => SANEFrameFormat.green,
      SANE_Frame.FRAME_BLUE => SANEFrameFormat.blue,
    };
  }
}

extension NativeSANEParametersExtension on SANE_Parameters {
  /// Convert native [SANE_Parameters] to [SANEParameters].
  SANEParameters toSANEParameters() {
    return SANEParameters(
      format: format.toSANEFrameFormat(),
      lastFrame: last_frame.toDartBool(),
      bytesPerLine: bytes_per_line,
      pixelsPerLine: pixels_per_line,
      lines: lines,
      depth: depth,
    );
  }
}

extension NativeSANEOptionValueTypeExtension on SANE_Value_Type {
  /// Convert native [SANE_Value_Type] to [SANEOptionValueType].
  SANEOptionValueType toSANEOptionValueType() {
    return switch (this) {
      SANE_Value_Type.TYPE_BOOL => SANEOptionValueType.bool,
      SANE_Value_Type.TYPE_INT => SANEOptionValueType.int,
      SANE_Value_Type.TYPE_FIXED => SANEOptionValueType.fixed,
      SANE_Value_Type.TYPE_STRING => SANEOptionValueType.string,
      SANE_Value_Type.TYPE_BUTTON => SANEOptionValueType.button,
      SANE_Value_Type.TYPE_GROUP => SANEOptionValueType.group,
    };
  }
}

extension NativeSANEOptionUnitExtension on SANE_Unit {
  /// Convert native [SANE_Unit] to [SANEOptionUnit].
  SANEOptionUnit toSANEOptionUnit() {
    return switch (this) {
      SANE_Unit.UNIT_NONE => SANEOptionUnit.none,
      SANE_Unit.UNIT_PIXEL => SANEOptionUnit.pixel,
      SANE_Unit.UNIT_BIT => SANEOptionUnit.bit,
      SANE_Unit.UNIT_MM => SANEOptionUnit.mm,
      SANE_Unit.UNIT_DPI => SANEOptionUnit.dpi,
      SANE_Unit.UNIT_PERCENT => SANEOptionUnit.percent,
      SANE_Unit.UNIT_MICROSECOND => SANEOptionUnit.microsecond,
    };
  }
}

extension SANEActionExtension on SANEControlAction {
  /// Convert [SANEControlAction] to native [SANE_Action].
  SANE_Action toNativeSANEAction() {
    return switch (this) {
      SANEControlAction.getValue => SANE_Action.ACTION_GET_VALUE,
      SANEControlAction.setValue => SANE_Action.ACTION_SET_VALUE,
      SANEControlAction.setAuto => SANE_Action.ACTION_SET_AUTO,
    };
  }
}

List<SANEOptionCapability> _saneOptionCapabilityFromBitset(int bitset) {
  final capabilities = <SANEOptionCapability>[];

  if (bitset & SANE_CAP_SOFT_SELECT != 0) {
    capabilities.add(SANEOptionCapability.softSelect);
  }
  if (bitset & SANE_CAP_HARD_SELECT != 0) {
    capabilities.add(SANEOptionCapability.hardSelect);
  }
  if (bitset & SANE_CAP_SOFT_DETECT != 0) {
    capabilities.add(SANEOptionCapability.softDetect);
  }
  if (bitset & SANE_CAP_EMULATED != 0) {
    capabilities.add(SANEOptionCapability.emulated);
  }
  if (bitset & SANE_CAP_AUTOMATIC != 0) {
    capabilities.add(SANEOptionCapability.automatic);
  }
  if (bitset & SANE_CAP_INACTIVE != 0) {
    capabilities.add(SANEOptionCapability.inactive);
  }
  if (bitset & SANE_CAP_ADVANCED != 0) {
    capabilities.add(SANEOptionCapability.advanced);
  }

  return capabilities;
}

SANEOptionConstraint? _saneConstraintFromNative(
  UnnamedUnion1 constraint,
  SANE_Constraint_Type constraintType,
  SANEOptionValueType valueType,
) {
  switch (constraintType) {
    case SANE_Constraint_Type.CONSTRAINT_NONE:
      return null;

    case SANE_Constraint_Type.CONSTRAINT_RANGE:
      if (valueType == SANEOptionValueType.int) {
        return SANEOptionConstraintRange<int>(
          min: constraint.range.ref.min,
          max: constraint.range.ref.max,
          quant: constraint.range.ref.quant,
        );
      }
      if (valueType == SANEOptionValueType.fixed) {
        return SANEOptionConstraintRange<double>(
          min: constraint.range.ref.min.toDartDouble(),
          max: constraint.range.ref.max.toDartDouble(),
          quant: constraint.range.ref.quant.toDartDouble(),
        );
      }
      throw Exception('Invalid option value type');

    case SANE_Constraint_Type.CONSTRAINT_WORD_LIST:
      if (valueType == SANEOptionValueType.int) {
        final wordList = <int>[];
        final itemsCount = constraint.word_list[0] + 1;
        for (var i = 1; i < itemsCount; i++) {
          final word = constraint.word_list[i];
          wordList.add(word);
        }
        return SANEOptionConstraintWordList<int>(wordList: wordList);
      }
      if (valueType == SANEOptionValueType.fixed) {
        final wordList = <double>[];
        final itemsCount = constraint.word_list[0] + 1;
        for (var i = 1; i < itemsCount; i++) {
          final word = constraint.word_list[i].toDartDouble();
          wordList.add(word);
        }
        return SANEOptionConstraintWordList<double>(wordList: wordList);
      }
      throw Exception('Invalid option value type');

    case SANE_Constraint_Type.CONSTRAINT_STRING_LIST:
      final stringList = <String>[];
      for (var i = 0; constraint.string_list[i] != ffi.nullptr; i++) {
        final string = constraint.string_list[i].toDartString();
        stringList.add(string);
      }
      return SANEOptionConstraintStringList(stringList: stringList);
  }
}

extension SANEOptionDescriptorExtension on SANE_Option_Descriptor {
  /// Convert native [SANE_Option_Descriptor] to [SANEOptionDescriptor].
  SANEOptionDescriptor toSANEOptionDescriptorWithIndex(int index) {
    return SANEOptionDescriptor(
      index: index,
      name: name.toDartString(),
      title: title.toDartString(),
      description: desc.toDartString(),
      type: type.toSANEOptionValueType(),
      unit: unit.toSANEOptionUnit(),
      size: size,
      capabilities: _saneOptionCapabilityFromBitset(cap),
      constraint: _saneConstraintFromNative(
        constraint,
        constraint_type,
        type.toSANEOptionValueType(),
      ),
    );
  }
}

extension SANEOptionInfoBitsetExtension on int {
  /// Convert native SANE option info bitset to [SANEOptionInfo] list.
  List<SANEOptionInfo> toSANEOptionInfoList() {
    final infos = <SANEOptionInfo>[];
    if (this & SANE_INFO_INEXACT != 0) {
      infos.add(SANEOptionInfo.inexact);
    }
    if (this & SANE_INFO_RELOAD_OPTIONS != 0) {
      infos.add(SANEOptionInfo.reloadOptions);
    }
    if (this & SANE_INFO_RELOAD_PARAMS != 0) {
      infos.add(SANEOptionInfo.reloadParams);
    }
    return infos;
  }
}

extension SANEBoolExtension on int {
  /// Convert native [SANE_Bool] to dart [bool].
  bool toDartBool() {
    switch (this) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        throw Exception();
    }
  }
}

extension BoolExtensions on bool {
  DartSANE_Word toSANEBool() => this ? SANE_TRUE : SANE_FALSE;
}

const int _saneFixedScaleFactor = 1 << SANE_FIXED_SCALE_SHIFT;

extension SANEFixedExtension on int {
  double toDartDouble() => this / _saneFixedScaleFactor;
}

extension DoubleExtension on double {
  int toSANEFixed() {
    return (this * _saneFixedScaleFactor).toInt();
  }
}

extension SANEStringExtension on SANE_String_Const {
  String toDartString() =>
      this == ffi.nullptr ? '' : cast<ffi.Utf8>().toDartString();
}

extension StringExtension on String {
  SANE_String_Const toSANEString() => toNativeUtf8().cast<SANE_Char>();
}

extension SANECharExtension on ffi.Pointer<SANE_Char> {
  void copyStringBytes(String string, {int? maxLenght}) {
    maxLenght = maxLenght ?? string.length;
    final utf8String = string.toSANEString();
    final stringBytes = utf8String.cast<ffi.Uint8>();

    for (var i = 0;; i++) {
      if (i < maxLenght - 1) {
        this[i] = stringBytes[i];
        continue;
      }

      this[i] = 0;
      break;
    }

    ffi.calloc.free(utf8String);
  }
}
