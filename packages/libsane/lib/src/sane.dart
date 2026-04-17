import 'dart:typed_data';

import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/dylib.dart';
import 'package:libsane/src/queries/cancel.dart';
import 'package:libsane/src/queries/close.dart';
import 'package:libsane/src/queries/control_option.dart';
import 'package:libsane/src/queries/exit.dart';
import 'package:libsane/src/queries/get_all_option_descriptors.dart';
import 'package:libsane/src/queries/get_devices.dart';
import 'package:libsane/src/queries/get_option_descriptor.dart';
import 'package:libsane/src/queries/get_parameters.dart';
import 'package:libsane/src/queries/init.dart';
import 'package:libsane/src/queries/open.dart';
import 'package:libsane/src/queries/read.dart';
import 'package:libsane/src/queries/start.dart';
import 'package:libsane/src/structures.dart';
import 'package:meta/meta.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

typedef AuthCallback = SANECredentials Function(String resourceName);

class SANE {
  factory SANE() => _instance ??= SANE._();
  SANE._();
  static SANE? _instance;

  @visibleForTesting
  QueryBus? bus;

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
  SANEVersion init({AuthCallback? authCallback}) {
    _initBus();
    final query = InitQuery(authCallback);
    final response = _handle(query);
    return response.version;
  }

  /// Disposes the SANE instance.
  ///
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  void exit() {
    _handle(const ExitQuery());
    bus = null;
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
  List<SANEDevice> getDevices({bool localOnly = true}) {
    final query = GetDevicesQuery(localOnly);
    final response = _handle(query);
    return response.devices;
  }

  /// Establish a connection to a particular device.
  ///
  /// If the call completes successfully, a handle for the device is returned.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANEDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SANEInvalidDataException] if the device nameis not valid.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  SANEHandle open(String name) {
    final query = OpenQuery(name);
    final response = _handle(query);
    return response.handle;
  }

  /// Shortcut for [open] with a [SANEDevice]
  SANEHandle openDevice(SANEDevice device) {
    return open(device.name);
  }

  /// Disposes the SANE device. Infers [cancel].
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  void close(SANEHandle handle) {
    final query = CloseQuery(handle);
    _handle(query);
  }

  SANEOptionDescriptor? getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) {
    final query = GetOptionDescriptorQuery(handle, index);
    final response = _handle(query);
    return response.optionDescriptor;
  }

  List<SANEOptionDescriptor> getAllOptionDescriptors(
    SANEHandle handle,
  ) {
    final query = GetAllOptionDescriptorsQuery(handle);
    final response = _handle(query);
    return response.optionDescriptors;
  }

  SANEOptionResult<bool> controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _handle(query);
    return response.optionResult;
  }

  SANEOptionResult<int> controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _handle(query);
    return response.optionResult;
  }

  SANEOptionResult<double> controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _handle(query);
    return response.optionResult;
  }

  SANEOptionResult<String> controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _handle(query);
    return response.optionResult;
  }

  SANEOptionResult<Null> controlButtonOption({
    required SANEHandle handle,
    required int index,
  }) {
    final query = ControlValueOptionQuery(
      handle,
      index,
      SANEControlAction.setValue,
      null,
    );
    final response = _handle(query);
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
  SANEParameters getParameters(SANEHandle handle) {
    final query = GetParametersQuery(handle);
    final response = _handle(query);
    return response.parameters;
  }

  /// Initiates acquisition of an image from the device.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANECancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SANEDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SANEJammedException] if the document feeder is jammed.
  /// - Throws [SANENoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SANECoverOpenException] if the scanner cover is open.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEInvalidDataException] if the sane cannot be started with the
  ///   current set of options. The frontend should reload the option
  ///   descriptors.
  ///
  /// See also:
  ///
  /// - [`sane_start`](https://sane-project.gitlab.io/standard/api.html#sane-start)
  void start(SANEHandle handle) {
    final query = StartQuery(handle);
    _handle(query);
  }

  /// Reads image data from the device.
  ///
  /// The returned [Uint8List] is [bufferSize] bytes long or less. If it is
  /// zero, the end of the frame has been reached.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANECancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SANEJammedException] if the document feeder is jammed.
  /// - Throws [SANENoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SANECoverOpenException] if the scanner cover is open.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_read`](https://sane-project.gitlab.io/standard/api.html#sane-read)
  Uint8List read(SANEHandle handle, int bufferSize) {
    final query = SyncReadQuery(handle, bufferSize);
    final response = _handle(query);
    return response.bytes;
  }

  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  void cancel(SANEHandle handle) {
    final query = CancelQuery(handle);
    _handle(query);
  }

  void _initBus() {
    if (bus != null) return;
    bus = QueryBus(
      handlers: [
        InitQueryHandler(dylib),
        ExitQueryHandler(dylib),
        GetDevicesQueryHandler(dylib),
        OpenQueryHandler(dylib),
        CloseQueryHandler(dylib),
        GetOptionDescriptorQueryHandler(dylib),
        GetAllOptionDescriptorsQueryHandler(dylib),
        ControlValueOptionQueryHandler<bool>(dylib),
        ControlValueOptionQueryHandler<int>(dylib),
        ControlValueOptionQueryHandler<double>(dylib),
        ControlValueOptionQueryHandler<String>(dylib),
        ControlValueOptionQueryHandler<Null>(dylib),
        ControlValueOptionQueryHandler(dylib),
        GetParametersQueryHandler(dylib),
        StartQueryHandler(dylib),
        SyncReadQueryHandler(dylib),
        CancelQueryHandler(dylib),
      ],
      context: SANEBusContext(),
    );
  }

  T _handle<T extends Response>(
    Query<T> query,
  ) {
    if (bus == null) {
      throw StateError(
        'The query bus has not been initialized, please call init() first.',
      );
    }
    return bus!.handle(query);
  }
}
