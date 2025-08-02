import 'dart:async';
import 'dart:isolate';

import 'package:libsane/src/dylib.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/messages/cancel.dart';
import 'package:libsane/src/isolate/messages/close.dart';
import 'package:libsane/src/isolate/messages/control_option.dart';
import 'package:libsane/src/isolate/messages/exception.dart';
import 'package:libsane/src/isolate/messages/exit.dart';
import 'package:libsane/src/isolate/messages/get_all_option_descriptors.dart';
import 'package:libsane/src/isolate/messages/get_devices.dart';
import 'package:libsane/src/isolate/messages/get_option_descriptor.dart';
import 'package:libsane/src/isolate/messages/get_parameters.dart';
import 'package:libsane/src/isolate/messages/init.dart';
import 'package:libsane/src/isolate/messages/open.dart';
import 'package:libsane/src/isolate/messages/read.dart';
import 'package:libsane/src/isolate/messages/start.dart';
import 'package:logging/logging.dart';

final _logger = Logger('sane');

class SaneIsolate {
  SaneIsolate._(
    this._isolate,
    this._sendPort,
  );

  final Isolate _isolate;
  final SendPort _sendPort;

  static Future<SaneIsolate> spawn() async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      receivePort.sendPort,
      onExit: receivePort.sendPort,
    );

    final sendPortCompleter = Completer<SendPort>();
    receivePort.listen((message) {
      switch (message) {
        case SendPort():
          sendPortCompleter.complete(message);
        case LogRecord():
          _logger.redirect(message);
        case null:
          receivePort.close();
      }
    });

    final sendPort = await sendPortCompleter.future;
    return SaneIsolate._(isolate, sendPort);
  }

  void kill() => _isolate.kill(priority: Isolate.immediate);

  Future<T> sendMessage<T extends IsolateResponse>(
    IsolateMessage<T> message,
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

    if (response is ExceptionResponse) {
      Error.throwWithStackTrace(
        response.exception,
        response.stackTrace,
      );
    }

    return response as T;
  }
}

void _entryPoint(SendPort sendPort) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.forEach(sendPort.send);

  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final context = SaneIsolateContext();
  final handlers = <Type, IsolateMessageHandler>{};

  void registerHandle<M extends IsolateMessage<R>, R extends IsolateResponse>(
    IsolateMessageHandler<M, R> handler,
  ) {
    handlers[M] = handler;
  }

  registerHandle(InitMessageHandler(dylib));
  registerHandle(ExitMessageHandler(dylib));
  registerHandle(GetDevicesMessageHandler(dylib));
  registerHandle(OpenMessageHandler(dylib));
  registerHandle(CloseMessageHandler(dylib));
  registerHandle(GetOptionDescriptorMessageHandler(dylib));
  registerHandle(GetAllOptionDescriptorsMessageHandler(dylib));
  registerHandle(ControlValueOptionMessageHandler<bool>(dylib));
  registerHandle(ControlValueOptionMessageHandler<int>(dylib));
  registerHandle(ControlValueOptionMessageHandler<double>(dylib));
  registerHandle(ControlValueOptionMessageHandler<String>(dylib));
  registerHandle(ControlValueOptionMessageHandler<Null>(dylib));
  registerHandle(ControlValueOptionMessageHandler(dylib));
  registerHandle(GetParametersMessageHandler(dylib));
  registerHandle(StartMessageHandler(dylib));
  registerHandle(ReadMessageHandler(dylib));
  registerHandle(CancelMessageHandler(dylib));

  late StreamSubscription<_IsolateMessageEnvelope> subscription;
  subscription = receivePort.cast<_IsolateMessageEnvelope>().listen(
    (envelope) async {
      final _IsolateMessageEnvelope(:message, :replyPort) = envelope;

      IsolateResponse response;

      try {
        response = handlers[message.runtimeType]!.handle(message, context);
      } on SaneException catch (exception, stackTrace) {
        response = ExceptionResponse(
          exception: exception,
          stackTrace: stackTrace,
        );
      } on SaneError catch (exception, stackTrace) {
        response = ExceptionResponse(
          exception: exception,
          stackTrace: stackTrace,
        );
      }

      replyPort.send(response);

      if (message is ExitMessage) {
        await subscription.cancel();
      }
    },
  );
}

class _IsolateMessageEnvelope {
  _IsolateMessageEnvelope({
    required this.replyPort,
    required this.message,
  });

  final SendPort replyPort;
  final IsolateMessage message;
}

abstract interface class IsolateMessage<T extends IsolateResponse> {}

abstract interface class IsolateResponse {}

abstract interface class IsolateMessageHandler<M extends IsolateMessage<R>,
    R extends IsolateResponse> {
  R handle(M message, SaneIsolateContext context);
}
