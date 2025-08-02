import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate/context.dart';
import 'package:sane/src/isolate/isolate.dart';
import 'package:sane/src/isolate/logger.dart';
import 'package:sane/src/structures.dart';

class CloseMessage implements IsolateMessage<CloseResponse> {
  const CloseMessage(this.handle);
  final SaneHandle handle;
}

class CloseResponse implements IsolateResponse {
  const CloseResponse();
}

class CloseMessageHandler
    implements IsolateMessageHandler<CloseMessage, CloseResponse> {
  const CloseMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  CloseResponse handle(CloseMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    libSane.sane_close(context.nativeHandles.get(message.handle));
    isolateLogger.finest('sane_close()');

    context.nativeHandles.remove(message.handle);

    return const CloseResponse();
  }
}
