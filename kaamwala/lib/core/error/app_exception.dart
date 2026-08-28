/// User-friendly application exception.
/// 
/// This class wraps technical errors with user-friendly messages.
/// Architecture (Phase 1 Section 3): UI never shows raw stack traces.
library;

/// Base exception for user-facing errors.
class AppException implements Exception {
  const AppException({
    required this.userMessage,
    this.technicalMessage,
    this.canRetry = true,
  });

  /// Friendly message shown to the user (NFR-USE-05: no jargon).
  final String userMessage;

  /// Technical details for logging/debugging (never shown to user).
  final String? technicalMessage;

  /// Whether the user can retry the operation.
  final bool canRetry;

  @override
  String toString() => 'AppException: $userMessage';
}

/// Network connectivity error.
class NetworkException extends AppException {
  const NetworkException([
    super.userMessage = 'Please check your internet connection.',
    super.technicalMessage,
    super.canRetry = true,
  ]);
}

/// Authentication error (OTP, session expired, etc.).
class AuthException extends AppException {
  const AuthException([
    super.userMessage = 'Could not verify. Please try again.',
    super.technicalMessage,
    super.canRetry = true,
  ]);
}

/// Payment processing error.
class PaymentException extends AppException {
  const PaymentException([
    super.userMessage = 'Payment failed. Try again.',
    super.technicalMessage,
    super.canRetry = true,
  ]);
}

/// Resource not found error.
class NotFoundException extends AppException {
  const NotFoundException([
    super.userMessage = 'Not found.',
    super.technicalMessage,
    super.canRetry = false,
  ]);
}

/// Server-side error.
class ServerException extends AppException {
  const ServerException([
    super.userMessage = 'Something went wrong. Try again.',
    super.technicalMessage,
    super.canRetry = true,
  ]);
}

/// Configuration/initialization error.
class ConfigurationException extends AppException {
  const ConfigurationException([
    super.userMessage = 'App configuration missing. Please contact support.',
    super.technicalMessage,
    super.canRetry = false,
  ]);
}

/// Validation error (invalid input).
class ValidationException extends AppException {
  const ValidationException([
    super.userMessage = 'Please check your input.',
    super.technicalMessage,
    super.canRetry = true,
  ]);
}
