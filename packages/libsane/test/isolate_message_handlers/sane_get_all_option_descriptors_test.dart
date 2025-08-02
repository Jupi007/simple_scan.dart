import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/sane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/get_all_option_descriptors.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.getAllOptionDescriptors()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      const handle = SaneHandle('deviceName');

      final handler = GetAllOptionDescriptorsMessageHandler(libsane);
      const message = GetAllOptionDescriptorsMessage(handle);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns a list of SaneOptionDescriptor', () {
      final libsane = MockLibSane();
      final context = SaneIsolateContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSaneHandle(nativeHandle.value, 'device-name');

      const descriptorLenght = 5;
      var callCount = 0;
      final descriptorPointers = <ffi.Pointer<SANE_Option_Descriptor>>[];
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        if (callCount++ < descriptorLenght) {
          final descriptorPointer = allocSaneOptionDescriptor();
          descriptorPointers.add(descriptorPointer);
          return descriptorPointer;
        }

        return ffi.nullptr;
      });

      final handler = GetAllOptionDescriptorsMessageHandler(libsane);
      final message = GetAllOptionDescriptorsMessage(handle);
      final response = handler.handle(message, context);
      expect(response.optionDescriptors.length, equals(descriptorLenght));

      for (final pointer in descriptorPointers) {
        ffi.calloc.free(pointer);
      }
      ffi.calloc.free(nativeHandle);
    });
  });
}
