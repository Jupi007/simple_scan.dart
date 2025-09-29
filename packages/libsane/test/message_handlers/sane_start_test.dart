import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/start.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.start()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = StartMessageHandler(libsane);
      const message = StartMessage(handle);

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
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = StartMessageHandler(libsane);
      final message = StartMessage(handle);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANEIoException>()),
      );

      ffi.calloc.free(nativeHandle);
    });

    test('returns normally', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      when(
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      final handler = StartMessageHandler(libsane);
      final message = StartMessage(handle);
      expect(() => handler.handle(message, context), returnsNormally);
    });
  });
}
