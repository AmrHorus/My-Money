import 'package:flutter/foundation.dart';

/// Base API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'ApiException: $message (code: $code, status: $statusCode)';
}

/// Authentication exception
class AuthException extends ApiException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.code,
  });
}

/// Network exception
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Server exception
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.code,
  });
}

/// Validation exception
class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.statusCode = 400,
    super.code = 'VALIDATION_ERROR',
  });
}

/// Not found exception
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.code = 'NOT_FOUND',
  });
}

/// Conflict exception
class ConflictException extends ApiException {
  const ConflictException({
    required super.message,
    super.statusCode = 409,
    super.code = 'CONFLICT',
  });
}

/// Rate limit exception
class RateLimitException extends ApiException {
  const RateLimitException({
    required super.message,
    super.statusCode = 429,
    super.code = 'RATE_LIMIT_EXCEEDED',
  });
}

/// Sync conflict exception
class SyncConflictException extends ApiException {
  final String? transactionId;
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;

  const SyncConflictException({
    required super.message,
    this.transactionId,
    this.localData,
    this.remoteData,
    super.statusCode = 409,
    super.code = 'SYNC_CONFLICT',
  });
}
