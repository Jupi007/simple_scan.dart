import 'dart:ffi' as ffi;

import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/queries/open.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.open()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      final handler = OpenQueryHandler(libsane);
      const query = OpenQuery('test');

      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('throws SANEStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      context.initialized = true;

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = OpenQueryHandler(libsane);
      const query = OpenQuery('test');
      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANEIoException>()),
      );
    });

    test('with device name string', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

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

      final handler = OpenQueryHandler(libsane);
      const query = OpenQuery(deviceName);
      final response = handler.handle(query, context);
      expect(response.handle.deviceName, equals(deviceName));
    });
  });
}
