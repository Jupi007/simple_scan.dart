import 'dart:async';
import 'dart:isolate';

import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/extensions.dart';
import 'package:logging/logging.dart';

typedef MessageBusBuilder = MessageBus Function();

class MessageBusIsolate {
  MessageBusIsolate._(
    this._isolate,
    this._sendPort,
  );

  final Isolate _isolate;
  final SendPort _sendPort;

  static Future<MessageBusIsolate> spawn(
    MessageBusBuilder busBuilder,
    Logger logger,
  ) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      _EntryPointParams(busBuilder, receivePort.sendPort),
      onExit: receivePort.sendPort,
    );

    final sendPortCompleter = Completer<SendPort>();
    receivePort.listen((message) {
      switch (message) {
        case SendPort():
          sendPortCompleter.complete(message);
        case LogRecord():
          logger.redirect(message);
        case null:
          receivePort.close();
      }
    });

    final sendPort = await sendPortCompleter.future;
    return MessageBusIsolate._(isolate, sendPort);
  }

  Future<void> exit() async {
    await handle(const _ExitIsolateMessage());
  }

  void kill() => _isolate.kill(priority: Isolate.immediate);

  Future<T> handle<T extends Response>(
    Message<T> message,
  ) async {
    final replyPort = ReceivePort();

    _sendPort.send(
      _IsolateMessageEnvelope(
        replyPort: replyPort.sendPort,
        message: message,
      ),
    );

    final response = await replyPort.first;
    replyPort.close();

    if (response is _ExceptionResponse) {
      Error.throwWithStackTrace(
        response.exception,
        response.stackTrace,
      );
    }

    return response as T;
  }
}

void _entryPoint<C extends BusContext>(
  _EntryPointParams params,
) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.forEach(params.sendPort.send);

  final receivePort = ReceivePort();
  params.sendPort.send(receivePort.sendPort);

  final messageBus = params.busBuilder();

  late StreamSubscription<_IsolateMessageEnvelope> subscription;
  subscription = receivePort.cast<_IsolateMessageEnvelope>().listen(
    (envelope) async {
      final _IsolateMessageEnvelope(:message, :replyPort) = envelope;

      if (message is _ExitIsolateMessage) {
        await subscription.cancel();
        replyPort.send(const _ExitIsolateResponse());
        return;
      }

      late final Response response;

      try {
        response = messageBus.handle(message);
      } on Exception catch (exception, stackTrace) {
        response = _ExceptionResponse(
          exception: exception,
          stackTrace: stackTrace,
        );
      } on Error catch (exception, stackTrace) {
        response = _ExceptionResponse(
          exception: exception,
          stackTrace: stackTrace,
        );
      }

      replyPort.send(response);
    },
  );
}

class _EntryPointParams {
  const _EntryPointParams(this.busBuilder, this.sendPort);
  final MessageBusBuilder busBuilder;
  final SendPort sendPort;
}

class _ExitIsolateMessage extends Message {
  const _ExitIsolateMessage();
}

class _ExitIsolateResponse extends Response {
  const _ExitIsolateResponse();
}

class _IsolateMessageEnvelope {
  _IsolateMessageEnvelope({
    required this.replyPort,
    required this.message,
  });

  final SendPort replyPort;
  final Message message;
}

class _ExceptionResponse implements Response {
  const _ExceptionResponse({
    required this.exception,
    required this.stackTrace,
  });

  final Object exception;
  final StackTrace stackTrace;
}
