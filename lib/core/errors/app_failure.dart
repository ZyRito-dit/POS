/// Domain-level failure types.
/// These are pure domain exceptions — no HTTP or Dio references leak in here.
sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

/// The supplied credentials are invalid.
final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure([
    super.message = 'Email atau kata sandi tidak valid.',
  ]);
}

/// The request was structurally malformed (validation error).
final class ValidationFailure extends AppFailure {
  const ValidationFailure([
    super.message = 'Data yang dikirim tidak valid.',
  ]);
}

/// No internet connection or the server is unreachable.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'Tidak dapat terhubung ke server. Periksa koneksi internet atau Wi-Fi lokal.',
  ]);
}

/// Server returned an unexpected non-2xx response.
final class ServerFailure extends AppFailure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// The session token is absent or has expired.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Sesi telah habis. Silakan login kembali.',
  ]);
}

/// Catch-all for unexpected runtime exceptions.
final class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Terjadi kesalahan sistem. Silakan coba lagi.',
  ]);
}
