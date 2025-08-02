import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/sane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/read.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.read()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = ReadMessageHandler(libsane);
      const message = ReadMessage(handle, 0);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('throw ArgumentError when bufferSize is <= 0', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      for (final bufferSize in [0, -128]) {
        final handler = ReadMessageHandler(libsane);
        final message = ReadMessage(handle, bufferSize);

        expect(
          () => handler.handle(message, context),
          throwsA(isA<ArgumentError>()),
        );
      }

      ffi.calloc.free(nativeHandle);
    });

    test('returns empty Uint8List when status is STATUS_EOF', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      when(
        () => libsane.sane_read(any(), any(), any(), any()),
      ).thenReturn(SANE_Status.STATUS_EOF);

      final handler = ReadMessageHandler(libsane);
      final message = ReadMessage(handle, 128);
      final response = handler.handle(message, context);
      expect(response.bytes.isEmpty, isTrue);

      ffi.calloc.free(nativeHandle);
    });

    test('returns Uint8List of scan data', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      when(
        () => libsane.sane_read(any(), any(), any(), any()),
      ).thenAnswer((invocation) {
        final bufferPointer =
            invocation.positionalArguments[1] as ffi.Pointer<ffi.UnsignedChar>;
        final bufferSize = invocation.positionalArguments[2] as int;
        final lengthPointer =
            invocation.positionalArguments[3] as ffi.Pointer<SANE_Int>;
        for (var i = 0; i < bufferSize; i++) {
          bufferPointer[i] = 255;
        }
        lengthPointer.value = bufferSize;

        return SANE_Status.STATUS_GOOD;
      });

      final handler = ReadMessageHandler(libsane);
      final message = ReadMessage(handle, 128);
      final response = handler.handle(message, context);
      expect(response.bytes.length, equals(128));

      ffi.calloc.free(nativeHandle);
    });
  });
}
