class BusContext {}

class QueryBus {
  QueryBus({
    required List<QueryHandler> handlers,
    required this.context,
  }) {
    for (var handler in handlers) {
      _handlers[handler.queryType] = handler;
    }
  }

  final Map<Type, QueryHandler> _handlers = {};
  final BusContext context;

  R handle<R extends Response>(Query<R> query) {
    final handler = _handlers[query.runtimeType] ??
        (throw StateError('No handler for ${query.runtimeType}'));
    return handler.handle(query, context) as R;
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
