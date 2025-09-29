import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';

class ExitMessage implements Message<ExitResponse> {
  const ExitMessage();
}

class ExitResponse implements Response {
  const ExitResponse();
}

class ExitMessageHandler
    extends MessageHandler<ExitMessage, ExitResponse, SANEBusContext> {
  const ExitMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  ExitResponse handle(ExitMessage message, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    context.initialized = false;
    libsane.sane_exit();
    logger.finest('sane_exit()');

    context.nativeHandles.clear();
    context.nativeAuthCallback?.close();
    context.nativeAuthCallback = null;

    return const ExitResponse();
  }
}
