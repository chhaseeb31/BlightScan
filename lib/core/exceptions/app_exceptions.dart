/// Global error handling and exception management
/// Centralized exception handling for production stability
library;

import 'package:flutter/material.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

class NetworkException extends AppException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
        );
}

class ValidationException extends AppException {
  ValidationException({required super.message})
      : super(
          code: 'VALIDATION_ERROR',
        );
}

class AuthenticationException extends AppException {
  AuthenticationException({String? message})
      : super(
          message: message ?? 'Authentication failed. Please login again.',
          code: 'AUTH_ERROR',
        );
}

class RepositoryException extends AppException {
  RepositoryException({required super.message})
      : super(
          code: 'REPO_ERROR',
        );
}

class MLException extends AppException {
  MLException({required super.message})
      : super(
          code: 'ML_ERROR',
        );
}

/// Global error handler
class AppErrorHandler {
  static void handleException(
    Object exception, {
    StackTrace? stackTrace,
    VoidCallback? onError,
  }) {
    debugPrint('=== ERROR ===');
    debugPrint('Exception: $exception');
    debugPrint('StackTrace: $stackTrace');
    debugPrint('===============');

    if (onError != null) {
      onError();
    }
  }

  static String getErrorMessage(Object exception) {
    if (exception is AppException) {
      return exception.message;
    }
    if (exception is FormatException) {
      return 'Invalid format. Please check your input.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(actionLabel ?? 'OK'),
          ),
        ],
      ),
    );
  }
}

/// Future error handler wrapper
extension FutureErrorHandler<T> on Future<T> {
  Future<T> handleError({
    required BuildContext? context,
    VoidCallback? onError,
  }) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      AppErrorHandler.handleException(
        e,
        stackTrace: stackTrace,
        onError: onError,
      );

      if (context != null && context.mounted) {
        AppErrorHandler.showErrorSnackbar(
          context,
          AppErrorHandler.getErrorMessage(e),
        );
      }

      rethrow;
    }
  }
}
