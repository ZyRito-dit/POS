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
      var profile = token.user ??
          UserProfile(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            username: cleanEmail,
            email: cleanEmail,
            fullName: cleanEmail.split('@').first,
            isActive: true,
            role: 'CASHIER',
          );

      // Fetch accessible outlets for the authenticated user (/api/v1/auth/me/outlets)
      final (outlets, _) = await repository.getAccessibleOutlets();
      final outletList = outlets ?? const <Outlet>[];
      ref.read(accessibleOutletsProvider.notifier).state = outletList;

      Outlet? activeOutlet;
      if (outletList.isNotEmpty) {
        if (profile.outletId != null) {
          activeOutlet = outletList.firstWhere(
            (o) => o.id == profile.outletId,
            orElse: () => outletList.first,
          );
        } else {
          activeOutlet = outletList.first;
        }
      } else {
        // Fallback default outlet if none returned (e.g. offline/mock environment)
        activeOutlet = const Outlet(
          id: 1,
          tenantId: 1,
          code: 'OUT-01',
          name: 'Kopi Kato - Cabang Sudirman',
          address: 'Gedung Plaza Sudirman Lt. Dasar, Jakarta',
          phone: '081234567891',
          timezone: 'Asia/Jakarta',
          status: 'ACTIVE',
        );
        ref.read(accessibleOutletsProvider.notifier).state = [activeOutlet];
      }

      // Ensure profile is synced with the active outlet ID
      if (profile.outletId == null || profile.outletId != activeOutlet.id) {
        profile = profile.copyWith(outletId: activeOutlet.id);
      }

      ref.read(selectedOutletProvider.notifier).state = activeOutlet;
      ref.read(currentUserProvider.notifier).state = profile;
      ref.read(isAuthenticatedSessionProvider.notifier).state = true;

      // Automatically prefetch catalog for the active outlet
      ref.read(posProductsProvider.notifier).fetchCatalog(outletId: activeOutlet.id);

      state = LoginSuccess(token);
    } else {
      state = const LoginFailure('Terjadi kesalahan saat memproses respon login.');
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(selectedOutletProvider.notifier).state = null;
    ref.read(accessibleOutletsProvider.notifier).state = const [];
    ref.read(isAuthenticatedSessionProvider.notifier).state = false;
    reset();
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

/// Tracks all accessible outlets for the currently authenticated user.
final accessibleOutletsProvider = StateProvider<List<Outlet>>((ref) => const []);

/// Tracks the active selected outlet for the current POS session.
final selectedOutletProvider = StateProvider<Outlet?>((ref) => null);

/// Tracks whether the user is currently logged into the authenticated session.
final isAuthenticatedSessionProvider = StateProvider<bool>((ref) => false);

/// Switches the active outlet, updates user context, and re-syncs the catalog.
void switchActiveOutlet(WidgetRef ref, Outlet newOutlet) {
  ref.read(selectedOutletProvider.notifier).state = newOutlet;
  final currentUser = ref.read(currentUserProvider);
  if (currentUser != null) {
    ref.read(currentUserProvider.notifier).state =
        currentUser.copyWith(outletId: newOutlet.id);
  }
  ref.read(posProductsProvider.notifier).fetchCatalog(outletId: newOutlet.id);
}

/// Session init provider checking stored tokens.
final sessionInitProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final hasSession = await authRepo.hasValidSession();
  ref.read(isAuthenticatedSessionProvider.notifier).state = hasSession;

  if (hasSession) {
    final (profile, _) = await authRepo.getCurrentUser();
    if (profile != null) {
      ref.read(currentUserProvider.notifier).state = profile;
    }

    final (outlets, _) = await authRepo.getAccessibleOutlets();
    final outletList = outlets ?? const <Outlet>[];
    ref.read(accessibleOutletsProvider.notifier).state = outletList;

    Outlet? activeOutlet;
    final currentProfile = ref.read(currentUserProvider);
    if (outletList.isNotEmpty) {
      if (currentProfile?.outletId != null) {
        activeOutlet = outletList.firstWhere(
          (o) => o.id == currentProfile!.outletId,
          orElse: () => outletList.first,
        );
      } else {
        activeOutlet = outletList.first;
      }
    } else {
      activeOutlet = const Outlet(
        id: 1,
        tenantId: 1,
        code: 'OUT-01',
        name: 'Kopi Kato - Cabang Sudirman',
        address: 'Gedung Plaza Sudirman Lt. Dasar, Jakarta',
        phone: '081234567891',
        timezone: 'Asia/Jakarta',
        status: 'ACTIVE',
      );
      ref.read(accessibleOutletsProvider.notifier).state = [activeOutlet];
    }

    if (currentProfile != null &&
        (currentProfile.outletId == null ||
            currentProfile.outletId != activeOutlet.id)) {
      ref.read(currentUserProvider.notifier).state =
          currentProfile.copyWith(outletId: activeOutlet.id);
    }
    ref.read(selectedOutletProvider.notifier).state = activeOutlet;
    ref.read(posProductsProvider.notifier).fetchCatalog(outletId: activeOutlet.id);
  }

  return hasSession;
});
