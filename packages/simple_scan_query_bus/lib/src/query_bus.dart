class BusContext {}

class QueryBus {
  QueryBus({
    required this.handlers,
    required this.context,
  });

  final List<QueryHandler> handlers;
  final BusContext context;

  R handle<R extends Response>(
    Query<R> query,
  ) {
    final handler = handlers.firstWhere(
      (handler) {
        return handler.queryType == query.runtimeType;
      },
      orElse: () => throw StateError(
        'No handler registered for query type: ${query.runtimeType}',
      ),
    );
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
