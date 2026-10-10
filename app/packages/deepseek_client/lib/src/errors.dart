class DeepSeekApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? error;
  final String? rawBody;

  const DeepSeekApiException({
    required this.statusCode,
    required this.message,
    this.error,
    this.rawBody,
  });

  @override
  String toString() {
    return 'DeepSeekApiException(statusCode: $statusCode, message: $message, error: $error)';
  }
}

class DeepSeekBadRequestException extends DeepSeekApiException {
  const DeepSeekBadRequestException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}

class DeepSeekAuthenticationException extends DeepSeekApiException {
  const DeepSeekAuthenticationException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}

class DeepSeekInsufficientBalanceException extends DeepSeekApiException {
  const DeepSeekInsufficientBalanceException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}

class DeepSeekInvalidParameterException extends DeepSeekApiException {
  const DeepSeekInvalidParameterException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}

class DeepSeekRateLimitException extends DeepSeekApiException {
  const DeepSeekRateLimitException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}

class DeepSeekServerException extends DeepSeekApiException {
  const DeepSeekServerException({
    required super.statusCode,
    required super.message,
    super.error,
    super.rawBody,
  });
}
