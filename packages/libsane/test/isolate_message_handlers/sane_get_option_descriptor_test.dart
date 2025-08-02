import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/sane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/get_option_descriptor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.getOptionDescriptor()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = GetOptionDescriptorMessageHandler(libsane);
      const message = GetOptionDescriptorMessage(handle, 0);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns a SaneOptionDescriptor', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      const descriptorIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        descriptorPointer = allocSaneOptionDescriptor();
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
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

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
