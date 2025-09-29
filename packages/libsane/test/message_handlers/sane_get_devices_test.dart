import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/get_devices.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_device_utils.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.getDevices()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      final handler = GetDevicesMessageHandler(libsane);
      const message = GetDevicesMessage(true);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('throws SANEStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      context.initialized = true;

      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenReturn(SANE_Status.STATUS_NO_MEM);

      final handler = GetDevicesMessageHandler(libsane);
      const message = GetDevicesMessage(true);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANENoMemoryException>()),
      );
    });

    test('with empty device list', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      context.initialized = true;

      late ffi.Pointer<ffi.Pointer<SANE_Device>> emptyDeviceArray;
      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenAnswer((invocation) {
        emptyDeviceArray = ffi.calloc<ffi.Pointer<SANE_Device>>(1);
        emptyDeviceArray[0] = ffi.nullptr;

        final devicesPointer = invocation.positionalArguments[0]
            as ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>;
        devicesPointer.value = emptyDeviceArray;

        return SANE_Status.STATUS_GOOD;
      });

      final handler = GetDevicesMessageHandler(libsane);
      const message = GetDevicesMessage(true);
      final response = handler.handle(message, context);
      expect(response.devices.length, equals(0));

      ffi.calloc.free(emptyDeviceArray);
    });

    test('with non-empty device list', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      context.initialized = true;

      late ffi.Pointer<ffi.Pointer<SANE_Device>> deviceArray;
      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenAnswer((invocation) {
        final device1 = allocSANEDevice(
          name: 'test:0',
          vendor: 'Foo',
          model: 'Bar 2400',
          type: 'flatbed',
        );
        final device2 = allocSANEDevice(
          name: 'test:1',
          vendor: 'BazCorp',
          model: 'ScanPro',
          type: 'sheetfed',
        );

        deviceArray = allocSANEDevicePointerArray([device1, device2]);
        final devicesPointer = invocation.positionalArguments[0]
            as ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>;
        devicesPointer.value = deviceArray;

        return SANE_Status.STATUS_GOOD;
      });

      final handler = GetDevicesMessageHandler(libsane);
      const message = GetDevicesMessage(true);
      final response = handler.handle(message, context);
      expect(response.devices.length, equals(2));

      freeDevicePtrArray(deviceArray);
    });
  });
}
