import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class StartMessage implements IsolateMessage<StartResponse> {
  const StartMessage(this.handle);
  final SaneHandle handle;
}

class StartResponse implements IsolateResponse {
  const StartResponse();
}

class StartMessageHandler
    implements IsolateMessageHandler<StartMessage, StartResponse> {
  const StartMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  StartResponse handle(StartMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    final status = libSane.sane_start(
      context.nativeHandles.get(message.handle),
    );
    isolateLogger.finest('sane_start() -> ${status.name}');

    status.check();

    return const StartResponse();
  }
}
