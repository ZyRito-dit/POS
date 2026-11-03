import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/utils/debug_logger.dart';

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
          suggestion = 'Periksa email dan password. Gunakan akun yang sudah terdaftar di Kato POS.';
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

  // Attach Bearer token from secure storage to every authenticated request.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
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
