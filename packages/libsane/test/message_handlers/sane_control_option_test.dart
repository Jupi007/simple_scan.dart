import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/queries/control_option.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.controlOption()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final boolHandler = ControlValueOptionQueryHandler<bool>(libsane);
      const boolQuery = ControlValueOptionQuery<bool>(
        handle,
        0,
        SANEControlAction.setAuto,
        null,
      );
      expect(
        () => boolHandler.handle(boolQuery, context),
        throwsA(isA<SANENotInitializedError>()),
      );

      final intHandler = ControlValueOptionQueryHandler<int>(libsane);
      const intQuery = ControlValueOptionQuery<int>(
        handle,
        0,
        SANEControlAction.setAuto,
        null,
      );
      expect(
        () => intHandler.handle(intQuery, context),
        throwsA(isA<SANENotInitializedError>()),
      );

      final doubleHandler = ControlValueOptionQueryHandler<double>(libsane);
      const doubleQuery = ControlValueOptionQuery<double>(
        handle,
        0,
        SANEControlAction.setAuto,
        null,
      );
      expect(
        () => doubleHandler.handle(doubleQuery, context),
        throwsA(isA<SANENotInitializedError>()),
      );

      final stringHandler = ControlValueOptionQueryHandler<String>(libsane);
      const stringQuery = ControlValueOptionQuery<String>(
        handle,
        0,
        SANEControlAction.setAuto,
        null,
      );
      expect(
        () => stringHandler.handle(stringQuery, context),
        throwsA(isA<SANENotInitializedError>()),
      );

      final nullHandler = ControlValueOptionQueryHandler<Null>(libsane);
      const nullQuery = ControlValueOptionQuery<Null>(
        handle,
        0,
        SANEControlAction.setAuto,
        null,
      );
      expect(
        () => nullHandler.handle(nullQuery, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('throws SANEStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      const optionIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));
        descriptorPointer = allocSANEOptionDescriptor(
          type: SANE_Value_Type.TYPE_STRING,
        );
        return descriptorPointer;
      });

      when(
        () => libsane.sane_control_option(any(), any(), any(), any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = ControlValueOptionQueryHandler<String>(libsane);
      final query = ControlValueOptionQuery<String>(
        handle,
        optionIndex,
        SANEControlAction.setValue,
        'test',
      );
      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANEIoException>()),
      );

      ffi.calloc.free(descriptorPointer);
      ffi.calloc.free(nativeHandle);
    });

    test('set an option', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      const optionIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));
        descriptorPointer = allocSANEOptionDescriptor(
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

      final handler = ControlValueOptionQueryHandler<String>(libsane);
      final query = ControlValueOptionQuery<String>(
        handle,
        optionIndex,
        SANEControlAction.setValue,
        'test',
      );
      final response = handler.handle(query, context);
      expect(response.optionResult.value, equals('test'));

      ffi.calloc.free(descriptorPointer);
      ffi.calloc.free(nativeHandle);
    });

    // TODO: test get/set, with all value types, with overflow, etc.
  });
}
