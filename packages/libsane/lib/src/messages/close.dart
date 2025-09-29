import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class CloseMessage implements Message<CloseResponse> {
  const CloseMessage(this.handle);
  final SANEHandle handle;
}

class CloseResponse implements Response {
  const CloseResponse();
}

class CloseMessageHandler
    extends MessageHandler<CloseMessage, CloseResponse, SANEBusContext> {
  const CloseMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  CloseResponse handle(CloseMessage message, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    libsane.sane_close(context.nativeHandles.get(message.handle));
    logger.finest('sane_close()');

    context.nativeHandles.remove(message.handle);

    return const CloseResponse();
  }
}
