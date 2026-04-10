// File: lib/core/network/api_client.dart
// ===========================================
// API CLIENT CONFIGURATION
// Dio-based HTTP client mirroring src/lib/api.ts
// ===========================================

import 'package:dio/dio.dart';

class ApiClient {
  static const String _defaultBaseUrl = 'http://localhost:3001/api';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Interceptor for logging (dev only)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // TODO: Add interceptor for token refresh
    // _dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) {
    //     final token = getToken();
    //     if (token != null) {
    //       options.headers['Authorization'] = 'Bearer $token';
    //     }
    //     handler.next(options);
    //   },
    // ));
  }

  // GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: queryParameters,
    );
    return response.data as T;
  }

  // POST request
  Future<T> post<T>(String endpoint, {dynamic data}) async {
    final response = await _dio.post(endpoint, data: data);
    return response.data as T;
  }

  // PUT request
  Future<T> put<T>(String endpoint, {dynamic data}) async {
    final response = await _dio.put(endpoint, data: data);
    return response.data as T;
  }

  // PATCH request
  Future<T> patch<T>(String endpoint, {dynamic data}) async {
    final response = await _dio.patch(endpoint, data: data);
    return response.data as T;
  }

  // DELETE request
  Future<T> delete<T>(String endpoint) async {
    final response = await _dio.delete(endpoint);
    return response.data as T;
  }
}
