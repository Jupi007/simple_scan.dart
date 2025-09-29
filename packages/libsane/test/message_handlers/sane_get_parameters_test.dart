import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/get_parameters.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_parameters_utils.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.getParameters()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = GetParametersMessageHandler(libsane);
      const message = GetParametersMessage(handle);

      expect(
        () => handler.handle(message, context),
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

      when(
        () => libsane.sane_get_parameters(any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = GetParametersMessageHandler(libsane);
      final message = GetParametersMessage(handle);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANEIoException>()),
      );

      ffi.calloc.free(nativeHandle);
    });

    test('returns SANEParameters', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      const pixelsPerLine = 512;
      when(
        () => libsane.sane_get_parameters(any(), any()),
      ).thenAnswer((invocation) {
        final parametersPointer =
            invocation.positionalArguments[1] as ffi.Pointer<SANE_Parameters>;
        assignToSANEParametersPointer(
          pointer: parametersPointer,
          pixelsPerLine: pixelsPerLine,
        );

        return SANE_Status.STATUS_GOOD;
      });

      final handler = GetParametersMessageHandler(libsane);
      final message = GetParametersMessage(handle);
      final response = handler.handle(message, context);
      expect(response.parameters.pixelsPerLine, pixelsPerLine);
    });
  });
}
