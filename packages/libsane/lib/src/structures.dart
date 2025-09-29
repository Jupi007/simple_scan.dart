import 'package:meta/meta.dart';

@immutable
class SANEVersion {
  const SANEVersion.fromCode(this.code);

  final int code;

  int get major => (code >> 24) & 0xff;

  int get minor => (code >> 16) & 0xff;

  int get build => (code >> 0) & 0xffff;

  @override
  String toString() => '$major.$minor.$build';

  @override
  bool operator ==(covariant SANEVersion other) => code == other.code;

  @override
  int get hashCode => code;
}

class SANECredentials {
  const SANECredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

class SANEDevice {
  const SANEDevice({
    required this.name,
    required this.vendor,
    required this.model,
    required this.type,
  });

  final String name;
  final String vendor;
  final String model;
  final String type;

  @override
  String toString() {
    return 'SANEDevice($name, $vendor, $model, $type)';
  }
}

@immutable
class SANEHandle {
  const SANEHandle(this.deviceName);
  final String deviceName;

  @override
  bool operator ==(Object other) =>
      other is SANEHandle && other.deviceName == deviceName;

  @override
  int get hashCode => deviceName.hashCode;
}

enum SANEFrameFormat {
  gray,
  rgb,
  red,
  green,
  blue;
}

class SANEParameters {
  const SANEParameters({
    required this.format,
    required this.lastFrame,
    required this.bytesPerLine,
    required this.pixelsPerLine,
    required this.lines,
    required this.depth,
  });

  final SANEFrameFormat format;
  final bool lastFrame;
  final int bytesPerLine;
  final int pixelsPerLine;
  final int lines;
  final int depth;

  @override
  String toString() {
    return 'SANEParameters($format, $lastFrame, $bytesPerLine, $pixelsPerLine, $lines, $depth)';
  }
}

enum SANEOptionValueType {
  bool,
  int,
  fixed,
  string,
  button,
  group;
}

enum SANEOptionUnit {
  none,
  pixel,
  bit,
  mm,
  dpi,
  percent,
  microsecond;
}

enum SANEOptionCapability {
  softSelect,
  hardSelect,
  softDetect,
  emulated,
  automatic,
  inactive,
  advanced;
}

abstract class SANEOptionConstraint {}

class SANEOptionConstraintRange<T extends num> implements SANEOptionConstraint {
  const SANEOptionConstraintRange({
    required this.min,
    required this.max,
    required this.quant,
  });

  final T min;

  final T max;

  final T quant;
}

class SANEOptionConstraintWordList<T extends num>
    implements SANEOptionConstraint {
  const SANEOptionConstraintWordList({
    required this.wordList,
  });

  final List<T> wordList;
}

class SANEOptionConstraintStringList implements SANEOptionConstraint {
  const SANEOptionConstraintStringList({
    required this.stringList,
  });

  final List<String> stringList;
}

class SANEOptionDescriptor {
  const SANEOptionDescriptor({
    required this.index,
    required this.name,
    required this.title,
    required this.description,
    required this.type,
    required this.unit,
    required this.size,
    required this.capabilities,
    required this.constraint,
  });

  final int index;
  final String? name;
  final String? title;
  final String? description;
  final SANEOptionValueType type;
  final SANEOptionUnit unit;
  final int size;
  final List<SANEOptionCapability> capabilities;
  final SANEOptionConstraint? constraint;

  @override
  String toString() {
    return 'SANEOptionDescriptor($name, $type, $unit, $capabilities, $constraint)';
  }
}

enum SANEControlAction {
  getValue,
  setValue,
  setAuto;
}

enum SANEOptionInfo {
  inexact,
  reloadOptions,
  reloadParams;
}

class SANEOptionResult<T> {
  const SANEOptionResult({
    required this.value,
    required this.infos,
  });

  final T value;
  final List<SANEOptionInfo> infos;
}

abstract final class SANEDeviceTypes {
  static const filmScanner = 'film scanner';
  static const flatbedScanner = 'flatbed scanner';
  static const frameGrabber = 'frame grabber';
  static const handheldScanner = 'handheld scanner';
  static const multiFunctionPeripheral = 'multi-function peripheral';
  static const sheetfedScanner = 'sheetfed scanner';
  static const stillCamera = 'still camera';
  static const videoCamera = 'video camera';
  static const virtualDevice = 'virtual device';
}
