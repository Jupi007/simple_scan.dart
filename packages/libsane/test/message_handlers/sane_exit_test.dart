import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/exit.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.exit()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      final handler = ExitMessageHandler(libsane);
      const message = ExitMessage();

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('initialized is false ans handle is cleared', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      final handler = ExitMessageHandler(libsane);
      const message = ExitMessage();

      expect(
        () => handler.handle(message, context),
        returnsNormally,
      );
      expect(
        () => context.nativeHandles.get(handle),
        throwsA(isA<SANEHandleClosedError>()),
      );
      expect(context.initialized, isFalse);

      ffi.calloc.free(nativeHandle);
    });
  });
}
