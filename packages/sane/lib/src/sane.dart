import 'dart:async';
import 'dart:typed_data';

import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/messages/cancel.dart';
import 'package:sane/src/isolate/messages/close.dart';
import 'package:sane/src/isolate/messages/control_option.dart';
import 'package:sane/src/isolate/messages/exit.dart';
import 'package:sane/src/isolate/messages/get_all_option_descriptors.dart';
import 'package:sane/src/isolate/messages/get_devices.dart';
import 'package:sane/src/isolate/messages/get_option_descriptor.dart';
import 'package:sane/src/isolate/messages/get_parameters.dart';
import 'package:sane/src/isolate/messages/init.dart';
import 'package:sane/src/isolate/messages/open.dart';
import 'package:sane/src/isolate/messages/read.dart';
import 'package:sane/src/isolate/messages/start.dart';
import 'package:sane/src/structures.dart';

typedef AuthCallback = SaneCredentials Function(String resourceName);

class Sane {
  SaneIsolate? _isolate;

  /// Initializes the SANE library.
  ///
  /// This function must be called before any other SANE function can be called.
  ///
  /// The authorization function may be called by a backend in response to any
  /// of the following calls: [open], [controlOption], [start].
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  Future<SaneVersion> init({AuthCallback? authCallback}) async {
    _isolate = _isolate ?? await SaneIsolate.spawn();
    final message = InitMessage(authCallback);
    final response = await _sendMessage(message);
    return response.version;
  }

  /// Disposes the SANE instance.
  ///
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  Future<void> exit() async {
    await _sendMessage(const ExitMessage());
    _isolate = null;
  }

  /// Queries the list of devices that are available.
  ///
  /// This method can be called repeatedly to detect when new devices become
  /// available. If argument [localOnly] is true, only local devices are
  /// returned (devices directly attached to the machine that SANE is running
  /// on). If it is `false`, the device list includes all remote devices that
  /// are accessible to the SANE library.
  ///
  /// See also:
  ///
  /// - [`sane_get_devices`](https://sane-project.gitlab.io/standard/api.html#sane-get-devices)
  Future<List<SaneDevice>> getDevices({bool localOnly = true}) async {
    final message = GetDevicesMessage(localOnly);
    final response = await _sendMessage(message);
    return response.devices;
  }

  /// Establish a connection to a particular device.
  ///
  /// If the call completes successfully, a handle for the device is returned.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SaneInvalidDataException] if the device nameis not valid.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  Future<SaneHandle> open(String name) async {
    final message = OpenMessage(name);
    final response = await _sendMessage(message);
    return response.handle;
  }

  /// Shortcut for [open] with a [SaneDevice]
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  /// Disposes the SANE device. Infers [cancel].
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  Future<void> close(SaneHandle handle) async {
    final message = CloseMessage(handle);
    await _sendMessage(message);
  }

  Future<SaneOptionDescriptor?> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) async {
    final message = GetOptionDescriptorMessage(handle, index);
    final response = await _sendMessage(message);
    return response.optionDescriptor;
  }

  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final message = GetAllOptionDescriptorsMessage(handle);
    final response = await _sendMessage(message);
    return response.optionDescriptors;
  }

  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneControlAction action,
    bool? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.optionResult;
  }

  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneControlAction action,
    int? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.optionResult;
  }

  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneControlAction action,
    double? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.optionResult;
  }

  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneControlAction action,
    String? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.optionResult;
  }

  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final message = ControlValueOptionMessage(
      handle,
      index,
      SaneControlAction.setValue,
      null,
    );
    final response = await _sendMessage(message);
    return response.optionResult;
  }

  /// Obtain the current scan parameters.
  ///
  /// The returned parameters are guaranteed to be accurate between the time
  /// a scan has been started.
  ///
  /// See also:
  ///
  /// - [`sane_get_parameters`](https://sane-project.gitlab.io/standard/api.html#sane-get-parameters)
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final message = GetParametersMessage(handle);
    final response = await _sendMessage(message);
    return response.parameters;
  }

  /// Initiates acquisition of an image from the device.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneInvalidDataException] if the sane cannot be started with the
  ///   current set of options. The frontend should reload the option
  ///   descriptors.
  ///
  /// See also:
  ///
  /// - [`sane_start`](https://sane-project.gitlab.io/standard/api.html#sane-start)
  Future<void> start(SaneHandle handle) async {
    final message = StartMessage(handle);
    await _sendMessage(message);
  }

  /// Reads image data from the device.
  ///
  /// The returned [Uint8List] is [bufferSize] bytes long or less. If it is
  /// zero, the end of the frame has been reached.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_read`](https://sane-project.gitlab.io/standard/api.html#sane-read)
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final message = ReadMessage(handle, bufferSize);
    final response = await _sendMessage(message);
    return response.bytes;
  }

  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  Future<void> cancel(SaneHandle handle) async {
    final message = CancelMessage(handle);
    await _sendMessage(message);
  }

  Future<T> _sendMessage<T extends IsolateResponse>(
    IsolateMessage<T> message,
  ) async {
    if (_isolate == null) {
      throw StateError(
        'The isolate has not been initialized, please call spawn() first.',
      );
    }
    return _isolate!.sendMessage(message);
  }
}

/// Predefined device types for [SaneDevice.type].
///
/// See also:
///
/// - [Predefined Device Information Strings](https://sane-project.gitlab.io/standard/api.html#vendor-names)
abstract final class SaneDeviceTypes {
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
