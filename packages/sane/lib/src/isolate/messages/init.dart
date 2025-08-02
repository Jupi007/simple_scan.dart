import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/logger.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class InitMessage implements IsolateMessage<InitResponse> {
  const InitMessage(this.authCallback);
  final AuthCallback? authCallback;
}

class InitResponse implements IsolateResponse {
  const InitResponse(this.version);
  final SaneVersion version;
}

class InitMessageHandler
    implements IsolateMessageHandler<InitMessage, InitResponse> {
  const InitMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  InitResponse handle(InitMessage message, SaneIsolateContext context) {
    if (context.initialized) throw SaneAlreadyInitializedError();

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
      final status = libSane.sane_init(versionCodePointer, callbackPtr);
      isolateLogger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;
      final version = SaneVersion.fromCode(versionCode);
      isolateLogger.finest('SANE version: $version');

      context.initialized = true;

      return InitResponse(version);
    } finally {
      ffi.calloc.free(versionCodePointer);
    }
  }
}
