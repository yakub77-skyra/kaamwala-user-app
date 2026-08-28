/// Error mapper that converts raw exceptions to user-friendly AppExceptions.
/// 
/// Architecture (Phase 1 Section 3):
/// - Repositories catch raw exceptions
/// - This mapper converts them to friendly messages
/// - UI never sees raw stack traces or technical jargon
library;

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaamwala/core/error/app_exception.dart';

/// Maps raw exceptions to user-friendly [AppException]s.
class ErrorMapper {
  const ErrorMapper._();

  /// Converts any exception to an [AppException] with a friendly message.
  static AppException map(Object e, [StackTrace? stack]) {
    // Already an AppException - return as-is
    if (e is AppException) return e;

    // Network errors
    if (e is SocketException || _isNetworkError(e)) {
      return const NetworkException();
    }

    // Timeout errors
    if (e is TimeoutException || _isTimeoutError(e)) {
      return const NetworkException('Connection timed out. Check your internet.');
    }

    // Supabase Auth errors
    if (e is AuthException) {
      return const AuthException();
    }

    // Supabase errors
    if (e is PostgrestException) {
      return _mapPostgrestError(e);
    }

    // Format/Type errors (indicates bug or bad data)
    if (e is FormatException || e is TypeError) {
      return const ServerException();
    }

    // HTTP errors by status code
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('403') || msg.contains('unauthorized')) {
      return const AuthException();
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return const NotFoundException();
    }
    if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
      return const ServerException('Server error. Please try again later.');
    }

    // Payment errors
    if (msg.contains('payment') || msg.contains('razorpay')) {
      return const PaymentException();
    }

    // Default fallback
    return const ServerException();
  }

  static AppException _mapPostgrestError(PostgrestException e) {
    final code = e.code?.toString() ?? '';
    final msg = e.message.toLowerCase();

    // Check for specific error codes
    if (code == 'PGRST116' || msg.contains('not found')) {
      return const NotFoundException();
    }
    if (code.startsWith('40') || msg.contains('unauthorized')) {
      return const AuthException();
    }
    if (code.startsWith('50') || msg.contains('timeout')) {
      return const ServerException();
    }

    return const ServerException();
  }

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection refused') ||
        msg.contains('dns') ||
        msg.contains('http');
  }

  static bool _isTimeoutError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('timeout') || msg.contains('timed out');
  }
}

/// Extension method for easy mapping on any Object.
extension ExceptionMapper on Object {
  /// Convert this exception to a user-friendly [AppException].
  AppException toAppException([StackTrace? stack]) {
    return ErrorMapper.map(this, stack);
  }
}
