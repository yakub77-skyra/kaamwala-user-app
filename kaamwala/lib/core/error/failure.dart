/// Typed error/result model.
/// Architecture rule (Phase 2 section 8): "Error handling at repository level -
/// Repositories catch exceptions and return typed results (Success/Failure).
/// UI never sees raw exceptions."
library;

sealed class Failure {
  const Failure(this.message);

  /// Human-readable message - NFR-USE-05: no technical jargon.
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network problem. Check your internet.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Could not verify. Please try again.']);
}

final class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed. Try again.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Try again.']);
}

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}

/// Maps raw exceptions into typed [Failure]s at the repository boundary.
Failure mapException(Object e) {
  if (e is FormatException || e is TypeError) {
    return const ServerFailure();
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('timeout') ||
      msg.contains('network')) {
    return const NetworkFailure();
  }
  if (msg.contains('401') || msg.contains('403') || msg.contains('jwt')) {
    return const AuthFailure();
  }
  if (msg.contains('404') || msg.contains('not found')) {
    return const NotFoundFailure();
  }
  return const ServerFailure();
}
