import 'dart:async';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:simple_scan_query_bus/src/query_bus.dart';

typedef QueryBusBuilder = QueryBus Function();

class QueryBusIsolate {
  QueryBusIsolate._(
    this._isolate,
    this._sendPort,
  );

  final Isolate _isolate;
  final SendPort _sendPort;

  static Future<QueryBusIsolate> spawn(
    QueryBusBuilder busBuilder,
    Logger logger,
  ) async {
    final receivePort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      _EntryPointParams(busBuilder, receivePort.sendPort),
      onExit: receivePort.sendPort,
    );

    final sendPortCompleter = Completer<SendPort>();
    receivePort.listen((query) {
      switch (query) {
        case SendPort():
          sendPortCompleter.complete(query);
        case LogRecord():
          logger.redirect(query);
        case null:
          receivePort.close();
      }
    });

    final sendPort = await sendPortCompleter.future;
    return QueryBusIsolate._(isolate, sendPort);
  }

  Future<void> exit() async {
    await handle(const _ExitIsolateQuery());
  }

  void kill() => _isolate.kill(priority: Isolate.immediate);

  Future<T> handle<T extends Response>(
    Query<T> query,
  ) async {
    final replyPort = ReceivePort();

    _sendPort.send(
      _IsolateQueryEnvelope(
        replyPort: replyPort.sendPort,
        query: query,
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

  final queryBus = params.busBuilder();

  late StreamSubscription<_IsolateQueryEnvelope> subscription;
  subscription = receivePort.cast<_IsolateQueryEnvelope>().listen(
    (envelope) async {
      final _IsolateQueryEnvelope(:query, :replyPort) = envelope;

      if (query is _ExitIsolateQuery) {
        await subscription.cancel();
        replyPort.send(const _ExitIsolateResponse());
        return;
      }

      late final Response response;

      try {
        response = queryBus.handle(query);
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
  final QueryBusBuilder busBuilder;
  final SendPort sendPort;
}

class _ExitIsolateQuery extends Query {
  const _ExitIsolateQuery();
}

class _ExitIsolateResponse extends Response {
  const _ExitIsolateResponse();
}

class _IsolateQueryEnvelope {
  _IsolateQueryEnvelope({
    required this.replyPort,
    required this.query,
  });

  final SendPort replyPort;
  final Query query;
}

class _ExceptionResponse implements Response {
  const _ExceptionResponse({
    required this.exception,
    required this.stackTrace,
  });

  final Object exception;
  final StackTrace stackTrace;
}

extension _LoggerExtension on Logger {
  void redirect(LogRecord record) {
    log(
      record.level,
      record.message,
      record.error,
      record.stackTrace,
      record.zone,
    );
  }
}
