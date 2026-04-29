// File: lib/core/network/api_client.dart
// ===========================================
// API CLIENT CONFIGURATION
// Dio-based HTTP client with JWT token management
// ===========================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Use current machine IP for physical Android device, localhost for web/desktop
  // Run `hostname -I` to get current IP if login fails on mobile
  static const String _defaultBaseUrl = 'http://192.168.1.50:3001/api';
  static const String _webBaseUrl = 'http://localhost:3001/api';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    // Detect platform for base URL
    // kIsWeb is true when running in browser; 10.0.2.2 is only for Android emulator
    final baseUrl = kIsWeb ? _webBaseUrl : _defaultBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Auth interceptor — automatically attach JWT token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid — clear stored token
          clearToken();
        }
        handler.next(error);
      },
    ));

    // Logging interceptor (dev only)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[API] $obj'),
    ));
  }

  // ─── Token Management ─────────────────────────
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─── HTTP Methods ─────────────────────────────

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    return await _dio.post(endpoint, data: data);
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    return await _dio.put(endpoint, data: data);
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    return await _dio.patch(endpoint, data: data);
  }

  Future<Response> delete(String endpoint, {dynamic data}) async {
    return await _dio.delete(endpoint, data: data);
  }

  /// Upload file with multipart form data
  Future<Response> uploadFile(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?extraFields,
    });
    return await _dio.post(endpoint, data: formData);
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;
}
