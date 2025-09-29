import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class InitMessage implements Message<InitResponse> {
  const InitMessage(this.authCallback);
  final AuthCallback? authCallback;
}

class InitResponse implements Response {
  const InitResponse(this.version);
  final SANEVersion version;
}

class InitMessageHandler
    extends MessageHandler<InitMessage, InitResponse, SANEBusContext> {
  const InitMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  InitResponse handle(InitMessage message, SANEBusContext context) {
    if (context.initialized) throw SANEAlreadyInitializedError();

    final authCallback = message.authCallback;

    void authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> usernamePointer,
      ffi.Pointer<SANE_Char> passwordPointer,
    ) {
      final credentials =
          authCallback!(resource.cast<ffi.Utf8>().toDartString());

      usernamePointer.copyStringBytes(
        credentials.username,
        maxLenght: SANE_MAX_USERNAME_LEN,
      );
      passwordPointer.copyStringBytes(
        credentials.password,
        maxLenght: SANE_MAX_PASSWORD_LEN,
      );
    }

    final versionCodePointer = ffi.calloc<SANE_Int>();
    context.nativeAuthCallback = authCallback != null
        ? ffi.NativeCallable<SANE_Auth_CallbackFunction>.isolateLocal(
            authCallbackAdapter,
          )
        : null;
    final callbackPtr =
        context.nativeAuthCallback?.nativeFunction ?? ffi.nullptr;

    try {
      final status = libsane.sane_init(versionCodePointer, callbackPtr);
      logger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;
      final version = SANEVersion.fromCode(versionCode);
      logger.finest('SANE version: $version');

      context.initialized = true;

      return InitResponse(version);
    } finally {
      ffi.calloc.free(versionCodePointer);
    }
  }
}
