// File: lib/core/network/api_client.dart
// ===========================================
// API CLIENT CONFIGURATION
// Dio-based HTTP client with JWT token management
// ===========================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../config/supabase_config.dart';

class ApiClient {
  // Use current machine IP for physical Android device, localhost for web/desktop
  // Run `hostname -I` to get current IP if login fails on mobile
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _defaultBaseUrl = 'http://10.140.173.125:3001/api';
  static const String _webBaseUrl = 'https://sman1cikalong.up.railway.app/api';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    // Detect platform for base URL
    // kIsWeb is true when running in browser; 10.0.2.2 is only for Android emulator
    final baseUrl = _configuredBaseUrl.isNotEmpty
        ? _configuredBaseUrl
        : (kIsWeb ? _webBaseUrl : _defaultBaseUrl);

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor — automatically attach JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final hadAuthHeader =
                error.requestOptions.headers['Authorization'] != null;
            final alreadyRetried =
                error.requestOptions.extra['authRetried'] == true;

            if (!hadAuthHeader && !alreadyRetried) {
              final token = await getToken();
              if (token != null && token.isNotEmpty) {
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $token';
                retryOptions.extra['authRetried'] = true;

                try {
                  final response = await _dio.fetch(retryOptions);
                  return handler.resolve(response);
                } catch (_) {
                  // Keep the original 401 path below if retry also fails.
                }
              }
            }

            if (hadAuthHeader) {
              // Token was sent but rejected — clear stored token.
              await clearToken();
            }
          }
          handler.next(error);
        },
      ),
    );

    // Logging interceptor (dev only)
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }

  // ─── Token Management ─────────────────────────
  static const String _tokenKey = 'auth_token';
  static String? _cachedToken;

  static Future<String?> getToken() async {
    try {
      if (SupabaseConfig.isConfigured) {
        final accessToken =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          return accessToken;
        }
      }
    } catch (_) {
      // Supabase is optional in tests and local development without dart-define.
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken ??= prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
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

  Future<Response> uploadBytes(
    String endpoint, {
    required List<int> bytes,
    required String filename,
    required String fieldName,
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      ...?extraFields,
    });
    return await _dio.post(endpoint, data: formData);
  }

  Future<Response<List<int>>> downloadBytes(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get<List<int>>(
      endpoint,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  /// Get Dio instance for advanced usage
  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;
}
