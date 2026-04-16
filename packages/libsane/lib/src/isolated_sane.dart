import 'dart:async';
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
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class IsolatedSANE implements SANE {
  @visibleForTesting
  QueyBusIsolate? isolatedBus;

  @override
  Future<SANEVersion> init({AuthCallback? authCallback}) async {
    await _initBus();
    final query = InitQuery(authCallback);
    final response = await _handle(query);
    return response.version;
  }

  @override
  Future<void> exit() async {
    await _handle(const ExitQuery());
    await isolatedBus?.exit();
    isolatedBus = null;
  }

  @override
  Future<List<SANEDevice>> getDevices({bool localOnly = true}) async {
    final query = GetDevicesQuery(localOnly);
    final response = await _handle(query);
    return response.devices;
  }

  @override
  Future<SANEHandle> open(String name) async {
    final query = OpenQuery(name);
    final response = await _handle(query);
    return response.handle;
  }

  @override
  Future<SANEHandle> openDevice(SANEDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SANEHandle handle) async {
    final query = CloseQuery(handle);
    await _handle(query);
  }

  @override
  Future<SANEOptionDescriptor?> getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) async {
    final query = GetOptionDescriptorQuery(handle, index);
    final response = await _handle(query);
    return response.optionDescriptor;
  }

  @override
  Future<List<SANEOptionDescriptor>> getAllOptionDescriptors(
    SANEHandle handle,
  ) async {
    final query = GetAllOptionDescriptorsQuery(handle);
    final response = await _handle(query);
    return response.optionDescriptors;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<SANEParameters> getParameters(SANEHandle handle) async {
    final query = GetParametersQuery(handle);
    final response = await _handle(query);
    return response.parameters;
  }

  @override
  Future<void> start(SANEHandle handle) async {
    final query = StartQuery(handle);
    await _handle(query);
  }

  @override
  Future<Uint8List> read(SANEHandle handle, int bufferSize) async {
    final query = IsolateReadQuery(handle, bufferSize);
    final response = await _handle(query);
    return response.bytes.materialize().asUint8List();
  }

  @override
  Future<void> cancel(SANEHandle handle) async {
    final query = CancelQuery(handle);
    await _handle(query);
  }

  Future<void> _initBus() async {
    if (isolatedBus != null) {
      return;
    }

    isolatedBus = await QueyBusIsolate.spawn(
      () => QueryBus(
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
          IsolateReadQueryHandler(dylib),
          CancelQueryHandler(dylib),
        ],
        context: SANEBusContext(),
      ),
      Logger('sane.isolate'),
    );
  }

  Future<T> _handle<T extends Response>(
    Query<T> query,
  ) async {
    if (isolatedBus == null) {
      throw StateError(
        'The isolated query bus has not been initialized, please call init() first.',
      );
    }
    return isolatedBus!.handle(query);
  }
}
