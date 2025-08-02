import 'dart:ffi' as ffi;

import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/open.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.open()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();

      final handler = OpenMessageHandler(libsane);
      const message = OpenMessage('test');

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('throws SaneStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();

      context.initialized = true;

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = OpenMessageHandler(libsane);
      const message = OpenMessage('test');
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneIoException>()),
      );
    });

    test('with device name string', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();

      context.initialized = true;

      const deviceName = 'deviceName';

      when(
        () => libsane.sane_open(any(), any()),
      ).thenAnswer((invocation) {
        final deviceNamePointer =
            invocation.positionalArguments[0] as ffi.Pointer<SANE_Char>;
        expect(deviceNamePointer.toDartString(), equals(deviceName));

        final handlePointer =
            invocation.positionalArguments[1] as ffi.Pointer<SANE_Handle>;
        handlePointer.value = SANE_Handle.fromAddress(0x1234);

        return SANE_Status.STATUS_GOOD;
      });

      final handler = OpenMessageHandler(libsane);
      const message = OpenMessage(deviceName);
      final response = handler.handle(message, context);
      expect(response.handle.deviceName, equals(deviceName));
    });
  });
}
