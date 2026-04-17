import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/queries/close.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.close()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = CloseQueryHandler(libsane);
      const query = CloseQuery(handle);

      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('handle can\'t be used after being closed', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      final handler = CloseQueryHandler(libsane);
      final query = CloseQuery(handle);

      expect(() => handler.handle(query, context), returnsNormally);
      expect(
        () => context.nativeHandles.get(handle),
        throwsA(isA<SANEHandleClosedError>()),
      );
      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANEHandleClosedError>()),
      );

      ffi.calloc.free(nativeHandle);
    });
  });
}
