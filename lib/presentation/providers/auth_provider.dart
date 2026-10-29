import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/data/repositories/auth_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';

/// Discriminated union for login form state.
sealed class LoginState {
  const LoginState();
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {  
  final AuthToken token;
  const LoginSuccess(this.token);
}

final class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

/// Manages the login form lifecycle and authentication session.
/// Integrates with [AuthRepository] to execute real API authentication against KatoPOS backend.
class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  Future<void> login({
    required String email,
    required String password,
    String? username,
  }) async {
    final cleanEmail = (email.isNotEmpty ? email : (username ?? '')).trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      state = const LoginFailure('Silakan masukkan email Anda');
      return;
    }

    if (cleanPassword.isEmpty) {
      state = const LoginFailure('Silakan masukkan kata sandi Anda');
      return;
    }

    state = const LoginLoading();

    final repository = ref.read(authRepositoryProvider);
    final (token, failure) = await repository.login(
      email: cleanEmail,
      password: cleanPassword,
    );

    if (failure != null) {
      state = LoginFailure(failure.message);
      return;
    }

    if (token != null) {
      // Setup current authenticated user in session
      final profile = token.user ??
          UserProfile(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            username: cleanEmail,
            email: cleanEmail,
            fullName: cleanEmail.split('@').first,
            isActive: true,
            role: 'CASHIER',
          );

      ref.read(currentUserProvider.notifier).state = profile;
      ref.read(isAuthenticatedSessionProvider.notifier).state = true;
      state = LoginSuccess(token);
    } else {
      state = const LoginFailure('Terjadi kesalahan saat memproses respon login.');
    }
  }

  void setFailure(String message) {
    state = LoginFailure(message);
  }

  void reset() => state = const LoginInitial();
}

final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

// ---------------------------------------------------------------------------

/// Discriminated union for registration form state.
sealed class RegisterState {
  const RegisterState();
}

final class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

final class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

final class RegisterSuccess extends RegisterState {
  final UserProfile user;
  const RegisterSuccess(this.user);
}

final class RegisterFailure extends RegisterState {
  final String message;
  const RegisterFailure(this.message);
}

/// Manages the register form's lifecycle.
class RegisterNotifier extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterInitial();

  Future<void> register({
    required String username,
    required String password,
    required String email,
    String? fullName,
    String role = 'staff',
  }) async {
    state = const RegisterLoading();

    final repository = ref.read(authRepositoryProvider);
    final (user, failure) = await repository.register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
    );

    if (failure != null) {
      state = RegisterFailure(failure.message);
      return;
    }

    if (user != null) {
      state = RegisterSuccess(user);
    } else {
      // Fallback for local staff registration in offline mode
      final newUser = ref.read(staffUsersProvider.notifier).createStaff(
            username: username,
            email: email,
            fullName: fullName,
            role: role,
          );
      state = RegisterSuccess(newUser);
    }
  }

  void reset() => state = const RegisterInitial();
}

final registerProvider = NotifierProvider<RegisterNotifier, RegisterState>(
  RegisterNotifier.new,
);

// ---------------------------------------------------------------------------

/// Tracks the global authenticated user session.
final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

/// Tracks whether the user is currently logged into the authenticated session.
final isAuthenticatedSessionProvider = StateProvider<bool>((ref) => false);

/// Session init provider checking stored tokens.
final sessionInitProvider = FutureProvider<bool>((ref) async {
  final hasSession = await ref.read(authRepositoryProvider).hasValidSession();
  ref.read(isAuthenticatedSessionProvider.notifier).state = hasSession;
  return hasSession;
});
