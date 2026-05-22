enum ApiError {
  // 404 not found
  notFound,
  // 403 forbidden
  permissionDenied,
  // 401 unauthorized, should login again
  loginRequired,
  // 400 bad request, validation error, usually data schema issue
  validationError,
  // network error, e.g. no internet connection
  networkError,
  // unknown error
  unknown,
}

class ApiException implements Exception {
  final ApiError error;
  final String? message;

  ApiException(this.error, [this.message]);

  @override
  String toString() {
    if (message != null) {
      return 'ApiException: $error, message: $message';
    }
    return 'ApiException: $error';
  }
}
