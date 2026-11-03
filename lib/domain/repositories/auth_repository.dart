import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';

/// Contract for all authentication operations.
/// The domain layer only depends on this interface - never on a concrete HTTP client.
abstract interface class AuthRepository {
  /// Authenticates user and persists token to secure storage.
  /// Returns [AuthToken] on success or [AppFailure] on any failure.
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  });

  /// Creates a new user account. Requires an existing admin token.
  Future<(UserProfile?, AppFailure?)> register({
    required String username,
    required String password,
    required String email,
    String? fullName,
  });

  /// Fetches the currently authenticated user's profile.
  Future<(UserProfile?, AppFailure?)> getCurrentUser();

  /// Retrieves list of accessible outlets for the authenticated user from `/api/v1/auth/me/outlets`.
  Future<(List<Outlet>?, AppFailure?)> getAccessibleOutlets();

  /// Clears the persisted token from secure storage (logout).
  Future<void> logout();

  /// Returns true if a valid token exists in secure storage.
  Future<bool> hasValidSession();
}
