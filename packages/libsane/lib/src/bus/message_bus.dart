class BusContext {}

class MessageBus<C extends BusContext> {
  MessageBus({
    required this.handlers,
    required this.context,
  });

  final List<MessageHandler> handlers;
  final BusContext context;

  R handle<R extends Response>(
    Message<R> message,
  ) {
    final handler = handlers.firstWhere(
      (handler) {
        return handler.messageType == message.runtimeType;
      },
      orElse: () => throw StateError(
        'No handler registered for message type: ${message.runtimeType}',
      ),
    );
    return handler.handle(message, context) as R;
  }
}

abstract class Message<T extends Response> {
  const Message();
}

abstract class Response {
  const Response();
}

abstract class MessageHandler<M extends Message<R>, R extends Response,
    C extends BusContext> {
  const MessageHandler();
  Type get messageType => M;
  R handle(M message, C context);
}
