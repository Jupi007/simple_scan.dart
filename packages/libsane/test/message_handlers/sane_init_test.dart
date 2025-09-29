import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/libsane.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/messages/init.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSANE);

  group('SyncSANE.init()', () {
    test('without auth callback', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      when(() => libsane.sane_init(any(), any())).thenAnswer((invocation) {
        final versionPtr =
            invocation.positionalArguments[0] as ffi.Pointer<SANE_Int>;
        versionPtr.value = 0x01020003;
        return SANE_Status.STATUS_GOOD;
      });

      final handler = InitMessageHandler(libsane);
      const message = InitMessage(null);
      final response = handler.handle(message, context);

      expect(context.initialized, isTrue);
      expect(response.version.toString(), equals('1.2.3'));
    });

    group('with auth callback', () {
      void authTestCase({
        required String username,
        String? expectedUsername,
        required String password,
        String? expectedPassword,
        required String resourceName,
      }) {
        final libsane = MockLibSANE();
        when(() => libsane.sane_init(any(), any()))
            .thenReturn(SANE_Status.STATUS_GOOD);

        SANECredentials authCallback(localResourceName) {
          expect(localResourceName, equals(resourceName));
          return SANECredentials(
            username: username,
            password: password,
          );
        }

        final context = SANEBusContext();
        final handler = InitMessageHandler(libsane);
        final message = InitMessage(authCallback);
        handler.handle(message, context);

        final capturedArguments =
            verify(() => libsane.sane_init(captureAny(), captureAny()))
                .captured;
        final nativeAuthCallbackPtr = capturedArguments[1]
            as ffi.Pointer<ffi.NativeFunction<SANE_Auth_CallbackFunction>>;

        final dartAuthCallback = nativeAuthCallbackPtr.asFunction<
            void Function(
              SANE_String_Const resource,
              ffi.Pointer<SANE_Char> username,
              ffi.Pointer<SANE_Char> password,
            )>();

        final usernamePointer = ffi.malloc<ffi.Char>(SANE_MAX_USERNAME_LEN);
        final passwordPointer = ffi.malloc<ffi.Char>(SANE_MAX_PASSWORD_LEN);

        dartAuthCallback(
          resourceName.toSANEString(),
          usernamePointer,
          passwordPointer,
        );

        expect(
          usernamePointer.toDartString(),
          equals(expectedUsername ?? username),
        );
        expect(
          passwordPointer.toDartString(),
          equals(expectedPassword ?? password),
        );
        expect(context.initialized, isTrue);

        ffi.malloc.free(usernamePointer);
        ffi.malloc.free(passwordPointer);
      }

      test('and normal credentials', () {
        authTestCase(
          username: 'username',
          password: 'password',
          resourceName: 'resourceName',
        );
      });

      test('and overflow credentials', () {
        authTestCase(
          username: 'u' * SANE_MAX_USERNAME_LEN * 5,
          expectedUsername: 'u' * (SANE_MAX_USERNAME_LEN - 1),
          password: 'p' * SANE_MAX_PASSWORD_LEN * 5,
          expectedPassword: 'p' * (SANE_MAX_PASSWORD_LEN - 1),
          resourceName: 'r' * 512,
        );
      });

      // TODO: test invalid LATIN-1 characters
    });

    test('throws SANEStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();

      when(() => libsane.sane_init(any(), any()))
          .thenReturn(SANE_Status.STATUS_IO_ERROR);

      final handler = InitMessageHandler(libsane);
      const message = InitMessage(null);
      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANEIoException>()),
      );
      expect(context.initialized, isFalse);
    });

    test('calling init twice throws SANEAlreadyInitializedError', () {
      final libsane = MockLibSANE();
      final context = SANEBusContext();
      context.initialized = true;

      final handler = InitMessageHandler(libsane);
      const message = InitMessage(null);

      expect(
        () => handler.handle(message, context),
        throwsA(isA<SANEAlreadyInitializedError>()),
      );
    });
  });
}
