class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const AppException(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    if (statusCode == null) return 'AppException: $message';
    return 'AppException($statusCode): $message';
  }
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode, super.cause});
}

class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode, super.cause});
}

class NeedEmailVerifyException extends AppException {
  final String challengeId;

  const NeedEmailVerifyException(
    super.message, {
    required this.challengeId,
    super.statusCode,
    super.cause,
  });
}
