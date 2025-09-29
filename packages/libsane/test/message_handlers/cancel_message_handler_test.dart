import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/cancel.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.cancel()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = CancelMessageHandler(libsane);
      const message = CancelMessage(handle);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('returns normally', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      final handler = CancelMessageHandler(libsane);
      final message = CancelMessage(handle);

      expect(
        () => handler.handle(message, context),
        returnsNormally,
      );

      ffi.calloc.free(nativeHandle);
    });
  });
}
