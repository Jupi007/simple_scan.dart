import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/sane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/control_option.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.controlOption()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final boolHandler = ControlValueOptionMessageHandler<bool>(libsane);
      const boolMessage = ControlValueOptionMessage<bool>(
        handle,
        0,
        SaneControlAction.setAuto,
        null,
      );
      expect(
        () => boolHandler.handle(boolMessage, context),
        throwsA(isA<SaneNotInitializedError>()),
      );

      final intHandler = ControlValueOptionMessageHandler<int>(libsane);
      const intMessage = ControlValueOptionMessage<int>(
        handle,
        0,
        SaneControlAction.setAuto,
        null,
      );
      expect(
        () => intHandler.handle(intMessage, context),
        throwsA(isA<SaneNotInitializedError>()),
      );

      final doubleHandler = ControlValueOptionMessageHandler<double>(libsane);
      const doubleMessage = ControlValueOptionMessage<double>(
        handle,
        0,
        SaneControlAction.setAuto,
        null,
      );
      expect(
        () => doubleHandler.handle(doubleMessage, context),
        throwsA(isA<SaneNotInitializedError>()),
      );

      final stringHandler = ControlValueOptionMessageHandler<String>(libsane);
      const stringMessage = ControlValueOptionMessage<String>(
        handle,
        0,
        SaneControlAction.setAuto,
        null,
      );
      expect(
        () => stringHandler.handle(stringMessage, context),
        throwsA(isA<SaneNotInitializedError>()),
      );

      final nullHandler = ControlValueOptionMessageHandler<Null>(libsane);
      const nullMessage = ControlValueOptionMessage<Null>(
        handle,
        0,
        SaneControlAction.setAuto,
        null,
      );
      expect(
        () => nullHandler.handle(nullMessage, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('throws SaneStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      const optionIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));
        descriptorPointer = allocSaneOptionDescriptor(
          type: SANE_Value_Type.TYPE_STRING,
        );
        return descriptorPointer;
      });

      when(
        () => libsane.sane_control_option(any(), any(), any(), any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = ControlValueOptionMessageHandler<String>(libsane);
      final message = ControlValueOptionMessage<String>(
        handle,
        optionIndex,
        SaneControlAction.setValue,
        'test',
      );
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneIoException>()),
      );

      ffi.calloc.free(descriptorPointer);
      ffi.calloc.free(nativeHandle);
    });

    test('set an option', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      const optionIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));
        descriptorPointer = allocSaneOptionDescriptor(
          type: SANE_Value_Type.TYPE_STRING,
        );
        return descriptorPointer;
      });

      when(
        () => libsane.sane_control_option(any(), any(), any(), any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));

        return SANE_Status.STATUS_GOOD;
      });

      final handler = ControlValueOptionMessageHandler<String>(libsane);
      final message = ControlValueOptionMessage<String>(
        handle,
        optionIndex,
        SaneControlAction.setValue,
        'test',
      );
      final response = handler.handle(message, context);
      expect(response.optionResult.value, equals('test'));

      ffi.calloc.free(descriptorPointer);
      ffi.calloc.free(nativeHandle);
    });

    // TODO: test get/set, with all value types, with overflow, etc.
  });
}
