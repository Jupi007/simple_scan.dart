import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/close.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.close()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = CloseMessageHandler(libsane);
      const message = CloseMessage(handle);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('handle can\'t be used after being closed', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      final handler = CloseMessageHandler(libsane);
      final message = CloseMessage(handle);

      expect(() => handler.handle(message, context), returnsNormally);
      expect(
        () => context.nativeHandles.get(handle),
        throwsA(isA<SaneHandleClosedError>()),
      );
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneHandleClosedError>()),
      );

      ffi.calloc.free(nativeHandle);
    });
  });
}
