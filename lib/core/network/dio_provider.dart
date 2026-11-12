import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/utils/debug_logger.dart';
import 'package:pos_apps_umkm/data/models/auth_dto.dart';

/// Enterprise Silent 401 Auto-Refresh & Retry Interceptor.
///
/// 1. Injects Bearer token from secure storage into headers of all outgoing requests.
/// 2. Intercepts HTTP 401 Unauthorized errors and silently calls /api/v1/auth/refresh
///    to obtain a fresh access token without disrupting active cashier operations.
/// 3. Retries the failed request transparently with the new access token.
/// 4. Implements concurrency locking so simultaneous 401s share a single refresh cycle.
/// 5. Protects against infinite retry loops via `is_retry` metadata check.
class AuthTokenInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Dio _refreshDio;
  Future<String?>? _refreshFuture;

  AuthTokenInterceptor({
    required Dio dio,
    required FlutterSecureStorage storage,
    Dio? refreshDio,
  })  : _dio = dio,
        _storage = storage,
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                headers: {'Content-Type': 'application/json'},
              ),
            );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach Bearer token if not explicitly provided or suppressed
    if (!options.headers.containsKey('Authorization') ||
        options.headers['Authorization'] == null) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;
    final path = requestOptions.path;

    // Filter out non-401s, auth routes, and already retried requests
    final isAuthEndpoint = path.contains(AppConstants.refreshTokenEndpoint) ||
        path.contains(AppConstants.loginEndpoint);
    final isAlreadyRetried = requestOptions.extra['is_retry'] == true;

    // Prevent silent renewal on missing server token claims (e.g. Tenant ID / Outlet ID)
    // Refreshing the token cannot resolve omitted backend claims from server-side JWT generation.
    final responseData = response?.data;
    final errorMessage = responseData is Map<String, dynamic>
        ? (responseData['message'] as String? ?? '').toLowerCase()
        : '';
    final isMissingClaim = errorMessage.contains('tenant id') ||
        errorMessage.contains('outlet id');

    if (response?.statusCode == 401 &&
        !isAuthEndpoint &&
        !isAlreadyRetried &&
        !isMissingClaim) {
      if (kDebugMode) {
        debugPrint(
          '[AuthTokenInterceptor] 401 Unauthorized on $path. Triggering silent token renewal...',
        );
      }

      try {
        final currentStoredToken =
            await _storage.read(key: AppConstants.tokenKey);
        final headerAuth =
            requestOptions.headers['Authorization'] as String?;
        final failedToken = headerAuth?.replaceFirst('Bearer ', '');

        String? tokenToUse;
        // If storage already contains a different/newer token than what failed,
        // another concurrent request has already refreshed it.
        if (currentStoredToken != null &&
            currentStoredToken.isNotEmpty &&
            currentStoredToken != failedToken) {
          tokenToUse = currentStoredToken;
        } else {
          // Serialize concurrent refresh requests
          _refreshFuture ??= _performTokenRefresh();
          tokenToUse = await _refreshFuture;
        }

        if (tokenToUse != null && tokenToUse.isNotEmpty) {
          requestOptions.headers['Authorization'] = 'Bearer $tokenToUse';
          requestOptions.extra['is_retry'] = true;

          final retryResponse = await _dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (retryError) {
        if (retryError is DioException) {
          return handler.next(retryError);
        }
      } finally {
        _refreshFuture = null;
      }
    }

    return handler.next(err);
  }

  Future<String?> _performTokenRefresh() async {
    try {
      final storedRefreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return null;
      }

      final response = await _refreshDio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refresh_token': storedRefreshToken},
      );

      final rawData = response.data;
      if (rawData is! Map<String, dynamic>) {
        return null;
      }

      final dto = TokenResponseDto.fromJson(rawData);
      final writes = <Future<void>>[
        _storage.write(key: AppConstants.tokenKey, value: dto.accessToken),
        _storage.write(key: AppConstants.tokenTypeKey, value: dto.tokenType),
      ];
      if (dto.refreshToken != null && dto.refreshToken!.isNotEmpty) {
        writes.add(_storage.write(
          key: AppConstants.refreshTokenKey,
          value: dto.refreshToken,
        ));
      }
      await Future.wait(writes);

      return dto.accessToken;
    } catch (_) {
      return null;
    }
  }
}

/// Provides a configured [Dio] instance with auth interceptor injected.
/// This is a lazy singleton - created once per app lifecycle.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // HTTP traffic logger - only active in debug builds, never in release
  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: false,
        maxWidth: 120,
      ),
    );
  }

  // Custom Terminal Debug Logger: Mencatat seluruh alur request/response ke terminal
  // dan menyimpan entri untuk widget debug terminal di layar.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final reqId = '${DateTime.now().millisecondsSinceEpoch}_${options.uri.path}';
        options.extra['debug_request_id'] = reqId;
        options.extra['debug_start_time'] = DateTime.now();

        DebugLogger.instance.logRequest(
          id: reqId,
          method: options.method,
          url: options.uri.toString(),
          headers: options.headers,
          body: options.data,
        );

        handler.next(options);
      },
      onResponse: (response, handler) {
        final reqId = response.requestOptions.extra['debug_request_id'] as String? ??
            '${DateTime.now().millisecondsSinceEpoch}';
        final startTime = response.requestOptions.extra['debug_start_time'] as DateTime?;
        final durationMs = startTime != null
            ? DateTime.now().difference(startTime).inMilliseconds
            : 0;

        DebugLogger.instance.logSuccess(
          id: reqId,
          method: response.requestOptions.method,
          url: response.requestOptions.uri.toString(),
          statusCode: response.statusCode ?? 200,
          durationMs: durationMs,
          responseBody: response.data,
        );

        handler.next(response);
      },
      onError: (DioException error, handler) {
        final reqId = error.requestOptions.extra['debug_request_id'] as String? ??
            '${DateTime.now().millisecondsSinceEpoch}';
        final startTime = error.requestOptions.extra['debug_start_time'] as DateTime?;
        final durationMs = startTime != null
            ? DateTime.now().difference(startTime).inMilliseconds
            : 0;

        String? serverMsg;
        String? serverCode;
        String? serverDetails;

        if (error.response?.data is Map<String, dynamic>) {
          final data = error.response!.data as Map<String, dynamic>;
          serverMsg = data['message'] as String?;
          if (data['error'] is Map) {
            final errMap = data['error'] as Map;
            serverCode = errMap['code']?.toString();
            serverDetails = errMap['details']?.toString();
          }
        }

        String suggestion = '';
        final path = error.requestOptions.path;
        if (error.response?.statusCode == 401) {
          if (serverMsg != null && serverMsg.toLowerCase().contains('tenant id')) {
            suggestion =
                'Masalah Konfigurasi Backend: Token dari backend tidak menyertakan klaim "tenant_id". Hubungi tim backend untuk menyertakan tenant_id pada payload JWT login/refresh kasir.';
          } else {
            suggestion =
                'Periksa email dan password. Gunakan akun yang sudah terdaftar di Kato POS.';
          }
        } else if (error.response?.statusCode == 400) {
          if (path.contains('/pos/checkout')) {
            suggestion = 'Validasi transaksi checkout gagal. Pastikan outlet aktif dan data pesanan sesuai.';
          } else if (path.contains('/auth/login')) {
            suggestion = 'Periksa kelengkapan input formulir login.';
          } else {
            suggestion = 'Format permintaan tidak valid (Bad Request). Periksa data input formulir atau payload.';
          }
        } else if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError) {
          suggestion = 'Server ${AppConstants.baseUrl} tidak merespon. Pastikan backend aktif dan perangkat berada di Wi-Fi yang sama.';
        }

        DebugLogger.instance.logError(
          id: reqId,
          method: error.requestOptions.method,
          url: error.requestOptions.uri.toString(),
          statusCode: error.response?.statusCode,
          durationMs: durationMs,
          responseBody: error.response?.data,
          errorMessage: serverMsg ?? error.message ?? 'Terjadi kesalahan jaringan',
          errorCode: serverCode,
          errorDetails: serverDetails,
          suggestion: suggestion.isNotEmpty ? suggestion : null,
        );

        handler.next(error);
      },
    ),
  );

  // Attach Silent 401 Auto-Refresh & Retry Interceptor
  dio.interceptors.add(
    AuthTokenInterceptor(
      dio: dio,
      storage: storage,
    ),
  );

  return dio;
});

/// Provides a [FlutterSecureStorage] instance.
/// Uses AES encryption on Android and Keychain on iOS.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);
