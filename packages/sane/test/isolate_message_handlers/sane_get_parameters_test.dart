import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/messages/get_parameters.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_parameters_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.getParameters()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = GetParametersMessageHandler(libsane);
      const message = GetParametersMessage(handle);

      expect(
        () => handler.handle(message, context),
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

      when(
        () => libsane.sane_get_parameters(any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = GetParametersMessageHandler(libsane);
      final message = GetParametersMessage(handle);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneIoException>()),
      );

      ffi.calloc.free(nativeHandle);
    });

    test('returns SaneParameters', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      const pixelsPerLine = 512;
      when(
        () => libsane.sane_get_parameters(any(), any()),
      ).thenAnswer((invocation) {
        final parametersPointer =
            invocation.positionalArguments[1] as ffi.Pointer<SANE_Parameters>;
        assignToSaneParametersPointer(
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
