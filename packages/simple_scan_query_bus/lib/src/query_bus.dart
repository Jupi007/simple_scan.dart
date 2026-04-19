abstract class BusContext {
  const BusContext();
}

typedef BusContextBuilder = BusContext Function();

class QueryBus {
  QueryBus({
    required List<QueryHandler> handlers,
    required this.contextBuilder,
  }) : _context = contextBuilder() {
    for (var handler in handlers) {
      _handlers[handler.queryType] = handler;
    }
  }

  final Map<Type, QueryHandler> _handlers = {};
  final BusContextBuilder contextBuilder;
  BusContext _context;

  R handle<R extends Response>(Query<R> query) {
    final handler = _handlers[query.runtimeType] ??
        (throw StateError('No handler for ${query.runtimeType}'));
    return handler.handle(query, _context) as R;
  }

  void resetContext() {
    _context = contextBuilder();
  }
}

abstract class Query<T extends Response> {
  const Query();
}

abstract class Response {
  const Response();
}

abstract class QueryHandler<M extends Query<R>, R extends Response,
    C extends BusContext> {
  const QueryHandler();
  Type get queryType => M;
  R handle(M query, C context);
}
