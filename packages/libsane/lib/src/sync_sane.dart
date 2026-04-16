import 'dart:typed_data';

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
import 'package:libsane/src/sane.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';
import 'package:meta/meta.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class SyncSANE implements SANE {
  @visibleForTesting
  QueryBus? bus;

  @override
  SANEVersion init({AuthCallback? authCallback}) {
    _initBus();
    final query = InitQuery(authCallback);
    final response = _handle(query);
    return response.version;
  }

  @override
  void exit() {
    _handle(const ExitQuery());
    bus = null;
  }

  @override
  List<SANEDevice> getDevices({bool localOnly = true}) {
    final query = GetDevicesQuery(localOnly);
    final response = _handle(query);
    return response.devices;
  }

  @override
  SANEHandle open(String name) {
    final query = OpenQuery(name);
    final response = _handle(query);
    return response.handle;
  }

  @override
  SANEHandle openDevice(SANEDevice device) {
    return open(device.name);
  }

  @override
  void close(SANEHandle handle) {
    final query = CloseQuery(handle);
    _handle(query);
  }

  @override
  SANEOptionDescriptor? getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) {
    final query = GetOptionDescriptorQuery(handle, index);
    final response = _handle(query);
    return response.optionDescriptor;
  }

  @override
  List<SANEOptionDescriptor> getAllOptionDescriptors(
    SANEHandle handle,
  ) {
    final query = GetAllOptionDescriptorsQuery(handle);
    final response = _handle(query);
    return response.optionDescriptors;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  SANEParameters getParameters(SANEHandle handle) {
    final query = GetParametersQuery(handle);
    final response = _handle(query);
    return response.parameters;
  }

  @override
  void start(SANEHandle handle) {
    final query = StartQuery(handle);
    _handle(query);
  }

  @override
  Uint8List read(SANEHandle handle, int bufferSize) {
    final query = SyncReadQuery(handle, bufferSize);
    final response = _handle(query);
    return response.bytes;
  }

  @override
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
