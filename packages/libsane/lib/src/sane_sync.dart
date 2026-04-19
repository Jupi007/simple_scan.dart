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
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

typedef AuthCallback = SANECredentials Function(String resourceName);

class SANESync {
  factory SANESync() => _instance ??= SANESync._();
  SANESync._()
      : _bus = QueryBus(
          handlers: _handlers,
          contextBuilder: SANEBusContext.new,
        );
  static SANESync? _instance;

  final QueryBus _bus;
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
    SyncReadQueryHandler(dylib),
    CancelQueryHandler(dylib),
  ];

  /// Synchronously initializes the SANE library.
  ///
  /// {@macro sane.init}
  SANEVersion init({AuthCallback? authCallback}) {
    final query = InitQuery(authCallback);
    final response = _bus.handle(query);
    return response.version;
  }

  /// Synchronously disposes the SANE instance.
  ///
  /// {@macro sane.exit}
  void exit() {
    _bus.handle(const ExitQuery());
    _bus.resetContext();
  }

  /// Synchronously queries the list of devices that are available.
  ///
  /// {@macro sane.get_devices}
  List<SANEDevice> getDevices({bool localOnly = true}) {
    final query = GetDevicesQuery(localOnly);
    final response = _bus.handle(query);
    return response.devices;
  }

  /// Synchronously establish a connection to a particular device.
  ///
  /// {@macro sane.open}
  SANEHandle open(String name) {
    final query = OpenQuery(name);
    final response = _bus.handle(query);
    return response.handle;
  }

  /// {@macro sane.open_device}
  SANEHandle openDevice(SANEDevice device) {
    return open(device.name);
  }

  /// Synchronously disposes the SANE device.
  ///
  /// {@macro sane.close}
  void close(SANEHandle handle) {
    final query = CloseQuery(handle);
    _bus.handle(query);
  }

  SANEOptionDescriptor? getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) {
    final query = GetOptionDescriptorQuery(handle, index);
    final response = _bus.handle(query);
    return response.optionDescriptor;
  }

  List<SANEOptionDescriptor> getAllOptionDescriptors(
    SANEHandle handle,
  ) {
    final query = GetAllOptionDescriptorsQuery(handle);
    final response = _bus.handle(query);
    return response.optionDescriptors;
  }

  SANEOptionResult<bool>? controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _bus.handle(query);
    return response.optionResult;
  }

  SANEOptionResult<int>? controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _bus.handle(query);
    return response.optionResult;
  }

  SANEOptionResult<double>? controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _bus.handle(query);
    return response.optionResult;
  }

  SANEOptionResult<String>? controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  }) {
    final query = ControlValueOptionQuery(handle, index, action, value);
    final response = _bus.handle(query);
    return response.optionResult;
  }

  SANEOptionResult<Null>? controlButtonOption({
    required SANEHandle handle,
    required int index,
  }) {
    final query = ControlValueOptionQuery(
      handle,
      index,
      SANEControlAction.setValue,
      null,
    );
    final response = _bus.handle(query);
    return response.optionResult;
  }

  /// Synchronously obtain the current scan parameters.
  ///
  /// {@macro sane.get_parameters}
  SANEParameters getParameters(SANEHandle handle) {
    final query = GetParametersQuery(handle);
    final response = _bus.handle(query);
    return response.parameters;
  }

  /// Synchronously initiates acquisition of an image from the device.
  ///
  /// {@macro sane.start}
  void start(SANEHandle handle) {
    final query = StartQuery(handle);
    _bus.handle(query);
  }

  /// Synchronously reads image data from the device.
  ///
  /// {@macro sane.read}
  Uint8List read(SANEHandle handle, int bufferSize) {
    final query = SyncReadQuery(handle, bufferSize);
    final response = _bus.handle(query);
    return response.bytes;
  }

  /// Synchronously cancel the currently pending operation.
  ///
  /// {@macro sane.cancel}
  void cancel(SANEHandle handle) {
    final query = CancelQuery(handle);
    _bus.handle(query);
  }
}
