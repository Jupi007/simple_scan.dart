import 'dart:async';
import 'dart:typed_data';

import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/bus/message_bus_isolate.dart';
import 'package:libsane/src/dylib.dart';
import 'package:libsane/src/messages/cancel.dart';
import 'package:libsane/src/messages/close.dart';
import 'package:libsane/src/messages/control_option.dart';
import 'package:libsane/src/messages/exit.dart';
import 'package:libsane/src/messages/get_all_option_descriptors.dart';
import 'package:libsane/src/messages/get_devices.dart';
import 'package:libsane/src/messages/get_option_descriptor.dart';
import 'package:libsane/src/messages/get_parameters.dart';
import 'package:libsane/src/messages/init.dart';
import 'package:libsane/src/messages/open.dart';
import 'package:libsane/src/messages/read.dart';
import 'package:libsane/src/messages/start.dart';
import 'package:libsane/src/sane.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class IsolatedSANE implements SANE {
  @visibleForTesting
  MessageBusIsolate? isolatedBus;

  @override
  Future<SANEVersion> init({AuthCallback? authCallback}) async {
    await _initBus();
    final message = InitMessage(authCallback);
    final response = await _handle(message);
    return response.version;
  }

  @override
  Future<void> exit() async {
    await _handle(const ExitMessage());
    await isolatedBus?.exit();
    isolatedBus = null;
  }

  @override
  Future<List<SANEDevice>> getDevices({bool localOnly = true}) async {
    final message = GetDevicesMessage(localOnly);
    final response = await _handle(message);
    return response.devices;
  }

  @override
  Future<SANEHandle> open(String name) async {
    final message = OpenMessage(name);
    final response = await _handle(message);
    return response.handle;
  }

  @override
  Future<SANEHandle> openDevice(SANEDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SANEHandle handle) async {
    final message = CloseMessage(handle);
    await _handle(message);
  }

  @override
  Future<SANEOptionDescriptor?> getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) async {
    final message = GetOptionDescriptorMessage(handle, index);
    final response = await _handle(message);
    return response.optionDescriptor;
  }

  @override
  Future<List<SANEOptionDescriptor>> getAllOptionDescriptors(
    SANEHandle handle,
  ) async {
    final message = GetAllOptionDescriptorsMessage(handle);
    final response = await _handle(message);
    return response.optionDescriptors;
  }

  @override
  Future<SANEOptionResult<bool>> controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _handle(message);
    return response.optionResult;
  }

  @override
  Future<SANEOptionResult<int>> controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _handle(message);
    return response.optionResult;
  }

  @override
  Future<SANEOptionResult<double>> controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _handle(message);
    return response.optionResult;
  }

  @override
  Future<SANEOptionResult<String>> controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _handle(message);
    return response.optionResult;
  }

  @override
  Future<SANEOptionResult<Null>> controlButtonOption({
    required SANEHandle handle,
    required int index,
  }) async {
    final message = ControlValueOptionMessage(
      handle,
      index,
      SANEControlAction.setValue,
      null,
    );
    final response = await _handle(message);
    return response.optionResult;
  }

  @override
  Future<SANEParameters> getParameters(SANEHandle handle) async {
    final message = GetParametersMessage(handle);
    final response = await _handle(message);
    return response.parameters;
  }

  @override
  Future<void> start(SANEHandle handle) async {
    final message = StartMessage(handle);
    await _handle(message);
  }

  @override
  Future<Uint8List> read(SANEHandle handle, int bufferSize) async {
    final message = IsolateReadMessage(handle, bufferSize);
    final response = await _handle(message);
    return response.bytes.materialize().asUint8List();
  }

  @override
  Future<void> cancel(SANEHandle handle) async {
    final message = CancelMessage(handle);
    await _handle(message);
  }

  Future<void> _initBus() async {
    if (isolatedBus != null) {
      return;
    }

    isolatedBus = await MessageBusIsolate.spawn(
      () => MessageBus(
        handlers: [
          InitMessageHandler(dylib),
          ExitMessageHandler(dylib),
          GetDevicesMessageHandler(dylib),
          OpenMessageHandler(dylib),
          CloseMessageHandler(dylib),
          GetOptionDescriptorMessageHandler(dylib),
          GetAllOptionDescriptorsMessageHandler(dylib),
          ControlValueOptionMessageHandler<bool>(dylib),
          ControlValueOptionMessageHandler<int>(dylib),
          ControlValueOptionMessageHandler<double>(dylib),
          ControlValueOptionMessageHandler<String>(dylib),
          ControlValueOptionMessageHandler<Null>(dylib),
          ControlValueOptionMessageHandler(dylib),
          GetParametersMessageHandler(dylib),
          StartMessageHandler(dylib),
          IsolateReadMessageHandler(dylib),
          CancelMessageHandler(dylib),
        ],
        context: SANEBusContext(),
      ),
      Logger('sane.isolate'),
    );
  }

  Future<T> _handle<T extends Response>(
    Message<T> message,
  ) async {
    if (isolatedBus == null) {
      throw StateError(
        'The isolated message bus has not been initialized, please call init() first.',
      );
    }
    return isolatedBus!.handle(message);
  }
}
