import 'dart:convert';
import 'package:http/http.dart' as http;

import '../error/exceptions.dart';

/// API service for making HTTP requests to the backend
class ApiService {
  final String baseUrl;
  final http.Client _client;

  String? _authToken;
  String? _refreshToken;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Set refresh token
  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  /// Clear tokens
  void clearTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  /// Get headers with authentication
  Map<String, String> _getHeaders({bool authenticated = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool authenticated = true,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: _getHeaders(authenticated: authenticated),
    );
    return _handleResponse(response);
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: _getHeaders(authenticated: authenticated),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await _client.put(
      uri,
      headers: _getHeaders(authenticated: authenticated),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await _client.patch(
      uri,
      headers: _getHeaders(authenticated: authenticated),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await _client.delete(
      uri,
      headers: _getHeaders(authenticated: authenticated),
    );
    return _handleResponse(response);
  }

  /// Handle HTTP response
  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final body = response.body;

    // Handle successful responses
    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return {};
      }
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        throw const ServerException(
          message: 'Invalid JSON response from server',
          code: 'INVALID_JSON',
        );
      }
    }

    // Handle error responses
    Map<String, dynamic> errorData = {};
    try {
      errorData = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // Ignore parsing errors for error responses
    }

    final message = errorData['message'] as String? ?? 'An error occurred';
    final code = errorData['code'] as String?;

    switch (statusCode) {
      case 401:
        throw AuthException(message: message, statusCode: statusCode, code: code);
      case 403:
        throw AuthException(message: message, statusCode: statusCode, code: code ?? 'FORBIDDEN');
      case 404:
        throw NotFoundException(message: message, statusCode: statusCode, code: code);
      case 409:
        if (code == 'SYNC_CONFLICT') {
          throw SyncConflictException(
            message: message,
            transactionId: errorData['transactionId'] as String?,
            localData: errorData['localData'] as Map<String, dynamic>?,
            remoteData: errorData['remoteData'] as Map<String, dynamic>?,
          );
        }
        throw ConflictException(message: message, statusCode: statusCode, code: code);
      case 422:
        throw ValidationException(
          message: message,
          fieldErrors: errorData['fieldErrors'] as Map<String, List<String>>?,
        );
      case 429:
        throw RateLimitException(message: message, statusCode: statusCode, code: code);
      default:
        if (statusCode >= 500) {
          throw ServerException(message: message, statusCode: statusCode, code: code);
        }
        throw ApiException(message: message, statusCode: statusCode, code: code);
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }

  String get _baseUrl => baseUrl.endsWith('/') 
      ? baseUrl.substring(0, baseUrl.length - 1) 
      : baseUrl;
}
