import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/queries/get_all_option_descriptors.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.getAllOptionDescriptors()', () {
    test('throw SANENotInitializedError when not initialized', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      const handle = SANEHandle('deviceName');

      final handler = GetAllOptionDescriptorsQueryHandler(libsane);
      const query = GetAllOptionDescriptorsQuery(handle);

      expect(
        () => handler.handle(query, context),
        throwsA(isA<SANENotInitializedError>()),
      );
    });

    test('returns a list of SANEOptionDescriptor', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      final nativeHandle = ffi.calloc<SANE_Handle>();

      context.initialized = true;
      final handle = context.nativeHandles
          .createSANEHandle(nativeHandle.value, 'device-name');

      const descriptorLenght = 5;
      var callCount = 0;
      final descriptorPointers = <ffi.Pointer<SANE_Option_Descriptor>>[];
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        if (callCount++ < descriptorLenght) {
          final descriptorPointer = allocSANEOptionDescriptor();
          descriptorPointers.add(descriptorPointer);
          return descriptorPointer;
        }

        return ffi.nullptr;
      });

      final handler = GetAllOptionDescriptorsQueryHandler(libsane);
      final query = GetAllOptionDescriptorsQuery(handle);
      final response = handler.handle(query, context);
      expect(response.optionDescriptors.length, equals(descriptorLenght));

      for (final pointer in descriptorPointers) {
        ffi.calloc.free(pointer);
      }
      ffi.calloc.free(nativeHandle);
    });
  });
}
