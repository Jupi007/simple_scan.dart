import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/messages/cancel.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.cancel()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = CancelMessageHandler(libsane);
      const message = CancelMessage(handle);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns normally', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

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
