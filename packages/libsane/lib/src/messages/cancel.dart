import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class CancelMessage implements Message<CancelResponse> {
  const CancelMessage(this.handle);
  final SANEHandle handle;
}

class CancelResponse implements Response {
  const CancelResponse();
}

class CancelMessageHandler
    extends MessageHandler<CancelMessage, CancelResponse, SANEBusContext> {
  const CancelMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  CancelResponse handle(CancelMessage message, SANEBusContext context) {
    if (!context.initialized) throw SANENotInitializedError();

    libsane.sane_cancel(
      context.nativeHandles.get(message.handle),
    );
    logger.finest('sane_cancel()');

    return const CancelResponse();
  }
}
