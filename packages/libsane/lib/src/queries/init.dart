import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class InitQuery implements Query<InitResponse> {
  const InitQuery(this.authCallback);
  final AuthCallback? authCallback;
}

class InitResponse implements Response {
  const InitResponse(this.version);
  final SANEVersion version;
}

class InitQueryHandler
    extends QueryHandler<InitQuery, InitResponse, SANEBusContext> {
  const InitQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  InitResponse handle(InitQuery query, SANEBusContext context) {
    if (context.initialized) throw SANEAlreadyInitializedError();

    final authCallback = query.authCallback;

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
      logger.finest('sane_init()');
      final status = libsane.sane_init(versionCodePointer, callbackPtr);
      logger.finest('  -> ${status.name}');

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
