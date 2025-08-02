import 'package:libsane/src/isolate/isolate.dart';

class ExceptionResponse implements IsolateResponse {
  const ExceptionResponse({
    required this.exception,
    required this.stackTrace,
  });

  final Object exception;
  final StackTrace stackTrace;
}
