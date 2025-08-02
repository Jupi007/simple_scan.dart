import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class CancelMessage implements IsolateMessage<CancelResponse> {
  const CancelMessage(this.handle);
  final SaneHandle handle;
}

class CancelResponse implements IsolateResponse {
  const CancelResponse();
}

class CancelMessageHandler
    implements IsolateMessageHandler<CancelMessage, CancelResponse> {
  const CancelMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  CancelResponse handle(CancelMessage message, SaneIsolateContext context) {
    if (!context.initialized) throw SaneNotInitializedError();

    libSane.sane_cancel(
      context.nativeHandles.get(message.handle),
    );
    isolateLogger.finest('sane_cancel()');

    return const CancelResponse();
  }
}
