import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/messages/start.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.start()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = StartMessageHandler(libsane);
      const message = StartMessage(handle);

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
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = StartMessageHandler(libsane);
      final message = StartMessage(handle);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneIoException>()),
      );

      ffi.calloc.free(nativeHandle);
    });

    test('returns normally', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      when(
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      final handler = StartMessageHandler(libsane);
      final message = StartMessage(handle);
      expect(() => handler.handle(message, context), returnsNormally);
    });
  });
}
