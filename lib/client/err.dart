import 'package:result_dart/result_dart.dart';

enum ClientError {
  unexpectedError,
  internalError,
}

typedef ClientResult<T extends Object> = AsyncResult<T, ClientError>;
