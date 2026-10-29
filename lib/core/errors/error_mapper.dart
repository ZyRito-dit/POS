import 'package:dio/dio.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';

/// Maps raw [DioException] instances to typed [AppFailure] domain errors.
/// This is the single translation boundary between transport and domain layers.
AppFailure mapDioExceptionToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure(
        'Koneksi ke server timeout. Periksa apakah server backend aktif dan responsif.',
      );

    case DioExceptionType.connectionError:
      return NetworkFailure(
        'Gagal terhubung ke server Kato POS di ${AppConstants.baseUrl}. '
        'Pastikan backend berjalan di port 8005 dan perangkat berada di jaringan Wi-Fi yang sama.',
      );

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      final extractedMessage = _extractDetailMessage(body);

      if (statusCode == 401) {
        return InvalidCredentialsFailure(
          extractedMessage ?? 'Email atau password salah.',
        );
      }

      if (statusCode == 400 || statusCode == 422) {
        return ValidationFailure(
          extractedMessage ?? 'Format input data login tidak valid.',
        );
      }

      if (statusCode == 403) {
        return InvalidCredentialsFailure(
          extractedMessage ?? 'Akses ditolak. Akun tidak memiliki izin akses.',
        );
      }

      final message = extractedMessage ??
          'Terjadi kesalahan pada server (HTTP $statusCode).';
      return ServerFailure(message, statusCode: statusCode);

    case DioExceptionType.cancel:
      return const UnknownFailure('Permintaan dibatalkan.');

    default:
      return const UnknownFailure(
        'Terjadi kesalahan jaringan atau server tidak terjangkau.',
      );
  }
}

String? _extractDetailMessage(dynamic body) {
  if (body is Map<String, dynamic>) {
    // 1. KatoPOS Standard Error Response: {"success": false, "message": "...", "error": {"code": "...", "details": "..."}}
    final message = body['message'];
    final error = body['error'];

    if (error is Map) {
      final details = error['details'];
      if (details is String && details.isNotEmpty) {
        return '$message ($details)';
      }
    }

    if (message is String && message.isNotEmpty) {
      return message;
    }

    // 2. FastAPI / Django standard format: {"detail": "..."}
    final detail = body['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) return first['msg']?.toString();
    }
  }
  return null;
}
