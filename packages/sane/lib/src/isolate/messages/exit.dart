import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/logger.dart';

class ExitMessage implements IsolateMessage<ExitResponse> {
  const ExitMessage();
}

class ExitResponse implements IsolateResponse {
  const ExitResponse();
}

class ExitMessageHandler
    implements IsolateMessageHandler<ExitMessage, ExitResponse> {
  const ExitMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  ExitResponse handle(ExitMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    context.initialized = false;
    libSane.sane_exit();
    isolateLogger.finest('sane_exit()');

    context.nativeHandles.clear();
    context.nativeAuthCallback?.close();
    context.nativeAuthCallback = null;

    return const ExitResponse();
  }
}
