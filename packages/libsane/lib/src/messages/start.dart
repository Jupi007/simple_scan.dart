import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class StartMessage implements Message<StartResponse> {
  const StartMessage(this.handle);
  final SANEHandle handle;
}

class StartResponse implements Response {
  const StartResponse();
}

class StartMessageHandler
    extends MessageHandler<StartMessage, StartResponse, SANEBusContext> {
  const StartMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  StartResponse handle(
    StartMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final status = libsane.sane_start(
      context.nativeHandles.get(message.handle),
    );
    logger.finest('sane_start() -> ${status.name}');

    status.check();

    return const StartResponse();
  }
}
