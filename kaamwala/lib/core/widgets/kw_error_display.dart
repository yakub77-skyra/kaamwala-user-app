/// Helper functions to display user-friendly error messages.
/// 
/// Architecture (Phase 1 Section 3):
/// - Never show raw stack traces to users
/// - Always use mapped friendly messages from [ErrorMapper]
/// - Consistent error display across the app
library;

import 'package:flutter/material.dart';

import 'package:kaamwala/core/error/app_exception.dart';
import 'package:kaamwala/core/error/error_mapper.dart';
import 'package:kaamwala/core/theme/app_theme.dart';

/// Shows a snackbar with a user-friendly error message.
void showErrorSnackBar(
  BuildContext context,
  Object error, [
  StackTrace? stack,
]) {
  final appException = ErrorMapper.map(error, stack);
  
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: KwSpacing.sm),
            Expanded(
              child: Text(appException.userMessage),
            ),
          ],
        ),
        backgroundColor: KwColors.red,
        behavior: SnackBarBehavior.floating,
        action: appException.canRetry
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Caller should handle retry logic
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
}

/// Shows a dialog with a user-friendly error message.
Future<void> showErrorDialog(
  BuildContext context,
  Object error, [
  StackTrace? stack, {
  String? title,
  VoidCallback? onRetry,
}) async {
  final appException = ErrorMapper.map(error, stack);
  
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.error_outline_rounded,
        color: KwColors.red,
        size: 48,
      ),
      title: Text(title ?? 'Error'),
      content: Text(appException.userMessage),
      actions: [
        if (appException.canRetry && onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Returns a user-friendly error message for display.
String getErrorMessage(Object error, [StackTrace? stack]) {
  final appException = ErrorMapper.map(error, stack);
  return appException.userMessage;
}

/// Logs technical error details (for debugging, never shown to user).
void logTechnicalError(Object error, [StackTrace? stack]) {
  debugPrint('=== TECHNICAL ERROR ===');
  debugPrint('Type: ${error.runtimeType}');
  debugPrint('Message: $error');
  if (stack != null) {
    debugPrint('Stack:\n$stack');
  }
  debugPrint('======================');
}
