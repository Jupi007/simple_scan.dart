import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/messages/exit.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.exit()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();

      final handler = ExitMessageHandler(libsane);
      const message = ExitMessage();

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('initialized is false ans handle is cleared', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      final handler = ExitMessageHandler(libsane);
      const message = ExitMessage();

      expect(
        () => handler.handle(message, context),
        returnsNormally,
      );
      expect(
        () => context.nativeHandles.get(handle),
        throwsA(isA<SaneHandleClosedError>()),
      );
      expect(context.initialized, isFalse);

      ffi.calloc.free(nativeHandle);
    });
  });
}
