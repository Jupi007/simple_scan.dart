import 'dart:async';
import 'dart:typed_data';

import 'package:libsane/libsane.dart';
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
import 'package:logging/logging.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class SANE {
  factory SANE() => _instance ??= SANE._();
  SANE._();
  static SANE? _instance;

  QueryBusIsolate? _isolatedBus;
  static final _handlers = <QueryHandler>[
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
    IsolateReadQueryHandler(dylib),
    CancelQueryHandler(dylib),
  ];

  /// Initializes the SANE library.
  ///
  /// {@template sane.init}
  /// This function must be called before any other SANE function can be called.
  ///
  /// The authorization function may be called by a backend in response to any
  /// of the following calls: [open], [controlOption], [start].
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  /// {@endtemplate}
  Future<SANEVersion> init({AuthCallback? authCallback}) async {
    await _initBus();
    final query = InitQuery(authCallback);
    final response = await _handle(query);
    return response.version;
  }

  /// Disposes the SANE instance.
  ///
  /// {@template sane.exit}
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  /// {@endtemplate}
  Future<void> exit() async {
    await _handle(const ExitQuery());
    await _isolatedBus?.exit();
    _isolatedBus = null;
  }

  /// Queries the list of devices that are available.
  ///
  /// {@template sane.get_devices}
  /// This method can be called repeatedly to detect when new devices become
  /// available. If argument [localOnly] is true, only local devices are
  /// returned (devices directly attached to the machine that SANE is running
  /// on). If it is `false`, the device list includes all remote devices that
  /// are accessible to the SANE library.
  ///
  /// See also:
  ///
  /// - [`sane_get_devices`](https://sane-project.gitlab.io/standard/api.html#sane-get-devices)
  /// {@endtemplate}
  Future<List<SANEDevice>> getDevices({bool localOnly = true}) async {
    final query = GetDevicesQuery(localOnly);
    final response = await _handle(query);
    return response.devices;
  }

  /// Establish a connection to a particular device.
  ///
  /// {@template sane.open}
  /// If the call completes successfully, a handle for the device is returned.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANEDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SANEInvalidDataException] if the device name is not valid.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  /// {@endtemplate}
  Future<SANEHandle> open(String name) async {
    final query = OpenQuery(name);
    final response = await _handle(query);
    return response.handle;
  }

  /// {@template sane.open_device}
  /// Shortcut for [open] with a [SANEDevice]
  /// {@endtemplate}
  Future<SANEHandle> openDevice(SANEDevice device) {
    return open(device.name);
  }

  /// Disposes the SANE device.
  ///
  /// {@template sane.close}
  /// Terminates the association between the [handle] and the device it represents.
  /// If the device is presently active, a call to [cancel] is performed first.
  /// After this function returns, [handle] must not be used anymore.
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  /// {@endtemplate}
  Future<void> close(SANEHandle handle) async {
    final query = CloseQuery(handle);
    await _handle(query);
  }

  Future<SANEOptionDescriptor?> getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) async {
    final query = GetOptionDescriptorQuery(handle, index);
    final response = await _handle(query);
    return response.optionDescriptor;
  }

  Future<List<SANEOptionDescriptor>> getAllOptionDescriptors(
    SANEHandle handle,
  ) async {
    final query = GetAllOptionDescriptorsQuery(handle);
    final response = await _handle(query);
    return response.optionDescriptors;
  }

  Future<SANEOptionResult<bool>> controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  }) async {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = await _handle(query);
    return response.optionResult;
  }

  Future<SANEOptionResult<int>> controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  }) async {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = await _handle(query);
    return response.optionResult;
  }

  Future<SANEOptionResult<double>> controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  }) async {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = await _handle(query);
    return response.optionResult;
  }

  Future<SANEOptionResult<String>> controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  }) async {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = await _handle(query);
    return response.optionResult;
  }

  Future<SANEOptionResult<Null>> controlButtonOption({
    required SANEHandle handle,
    required int index,
  }) async {
    final query = ControlValueOptionQuery(
      handle,
      index,
      SANEControlAction.setValue,
      null,
    );
    final response = await _handle(query);
    return response.optionResult;
  }

  /// Obtain the current scan parameters.
  ///
  /// {@template sane.get_parameters}
  /// The returned parameters are guaranteed to be accurate between the time
  /// a scan has been started.
  ///
  /// See also:
  ///
  /// - [`sane_get_parameters`](https://sane-project.gitlab.io/standard/api.html#sane-get-parameters)
  /// {@endtemplate}
  Future<SANEParameters> getParameters(SANEHandle handle) async {
    final query = GetParametersQuery(handle);
    final response = await _handle(query);
    return response.parameters;
  }

  /// Initiates acquisition of an image from the device.
  ///
  /// {@template sane.start}
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
  /// {@endtemplate}
  Future<void> start(SANEHandle handle) async {
    final query = StartQuery(handle);
    await _handle(query);
  }

  /// Reads image data from the device.
  ///
  /// {@template sane.read}
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
  /// {@endtemplate}
  Future<Uint8List> read(SANEHandle handle, int bufferSize) async {
    final query = IsolateReadQuery(handle, bufferSize);
    final response = await _handle(query);
    return response.bytes.materialize().asUint8List();
  }

  /// Cancel the currently pending operation.
  ///
  /// {@template sane.cancel}
  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  /// {@endtemplate}
  Future<void> cancel(SANEHandle handle) async {
    final query = CancelQuery(handle);
    await _handle(query);
  }

  Future<void> _initBus() async {
    if (_isolatedBus != null) {
      return;
    }

    _isolatedBus = await QueryBusIsolate.spawn(
      () => QueryBus(
        handlers: _handlers,
        contextBuilder: SANEBusContext.new,
      ),
      Logger('sane.isolate'),
    );
  }

  Future<T> _handle<T extends Response>(
    Query<T> query,
  ) async {
    if (_isolatedBus == null) {
      throw StateError(
        'The isolated query bus has not been initialized, please call init() first.',
      );
    }
    return _isolatedBus!.handle(query);
  }
}
