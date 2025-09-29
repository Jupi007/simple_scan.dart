import 'dart:typed_data';

import 'package:libsane/src/bus/message_bus.dart';
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
import 'package:meta/meta.dart';

class SyncSANE implements SANE {
  @visibleForTesting
  MessageBus? bus;

  @override
  SANEVersion init({AuthCallback? authCallback}) {
    _initBus();
    final message = InitMessage(authCallback);
    final response = _handle(message);
    return response.version;
  }

  @override
  void exit() {
    _handle(const ExitMessage());
    bus = null;
  }

  @override
  List<SANEDevice> getDevices({bool localOnly = true}) {
    final message = GetDevicesMessage(localOnly);
    final response = _handle(message);
    return response.devices;
  }

  @override
  SANEHandle open(String name) {
    final message = OpenMessage(name);
    final response = _handle(message);
    return response.handle;
  }

  @override
  SANEHandle openDevice(SANEDevice device) {
    return open(device.name);
  }

  @override
  void close(SANEHandle handle) {
    final message = CloseMessage(handle);
    _handle(message);
  }

  @override
  SANEOptionDescriptor? getOptionDescriptor(
    SANEHandle handle,
    int index,
  ) {
    final message = GetOptionDescriptorMessage(handle, index);
    final response = _handle(message);
    return response.optionDescriptor;
  }

  @override
  List<SANEOptionDescriptor> getAllOptionDescriptors(
    SANEHandle handle,
  ) {
    final message = GetAllOptionDescriptorsMessage(handle);
    final response = _handle(message);
    return response.optionDescriptors;
  }

  @override
  SANEOptionResult<bool> controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  }) {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = _handle(message);
    return response.optionResult;
  }

  @override
  SANEOptionResult<int> controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  }) {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = _handle(message);
    return response.optionResult;
  }

  @override
  SANEOptionResult<double> controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  }) {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = _handle(message);
    return response.optionResult;
  }

  @override
  SANEOptionResult<String> controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  }) {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = _handle(message);
    return response.optionResult;
  }

  @override
  SANEOptionResult<Null> controlButtonOption({
    required SANEHandle handle,
    required int index,
  }) {
    final message = ControlValueOptionMessage(
      handle,
      index,
      SANEControlAction.setValue,
      null,
    );
    final response = _handle(message);
    return response.optionResult;
  }

  @override
  SANEParameters getParameters(SANEHandle handle) {
    final message = GetParametersMessage(handle);
    final response = _handle(message);
    return response.parameters;
  }

  @override
  void start(SANEHandle handle) {
    final message = StartMessage(handle);
    _handle(message);
  }

  @override
  Uint8List read(SANEHandle handle, int bufferSize) {
    final message = SyncReadMessage(handle, bufferSize);
    final response = _handle(message);
    return response.bytes;
  }

  @override
  void cancel(SANEHandle handle) {
    final message = CancelMessage(handle);
    _handle(message);
  }

  void _initBus() {
    if (bus != null) return;
    bus = MessageBus(
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
        SyncReadMessageHandler(dylib),
        CancelMessageHandler(dylib),
      ],
      context: SANEBusContext(),
    );
  }

  T _handle<T extends Response>(
    Message<T> message,
  ) {
    if (bus == null) {
      throw StateError(
        'The message bus has not been initialized, please call init() first.',
      );
    }
    return bus!.handle(message);
  }
}
