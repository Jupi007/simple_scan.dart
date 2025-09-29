import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/messages/get_option_descriptor.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.getOptionDescriptor()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = GetOptionDescriptorMessageHandler(libsane);
      const message = GetOptionDescriptorMessage(handle, 0);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('returns a SANEOptionDescriptor', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      const descriptorIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        descriptorPointer = allocSANEOptionDescriptor();
        return descriptorPointer;
      });

      final handler = GetOptionDescriptorMessageHandler(libsane);
      final message = GetOptionDescriptorMessage(handle, descriptorIndex);
      final response = handler.handle(message, context);
      expect(response.optionDescriptor!.index, equals(descriptorIndex));

      ffi.calloc.free(descriptorPointer);
      ffi.calloc.free(nativeHandle);
    });

    test('returns null when libsane returns nullptr', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenReturn(ffi.nullptr);

      final handler = GetOptionDescriptorMessageHandler(libsane);
      final message = GetOptionDescriptorMessage(handle, 1);
      final response = handler.handle(message, context);
      expect(response.optionDescriptor, equals(null));

      ffi.calloc.free(nativeHandle);
    });
  });
}
