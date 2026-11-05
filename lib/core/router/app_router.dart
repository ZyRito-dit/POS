import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/auth/forgot_password_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/auth/login_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/home/home_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/payment_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/payment_success_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/product_detail_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/transactions_view.dart';

/// Named route constants - single source of truth for all route paths.
abstract class AppRoutes {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String payment = '/payment';
  static const String paymentCash = '/payment/cash';
  static const String paymentQris = '/payment/qris';
  static const String paymentSuccess = '/payment/success';
  static const String transactions = '/transactions';
  static String productDetail(int id) => '/product/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final hasSession = ref.watch(isAuthenticatedSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isForgotPasswordRoute =
          state.matchedLocation == AppRoutes.forgotPassword;

      // Already authenticated -> skip auth screens
      if (hasSession && (isLoginRoute || isForgotPasswordRoute)) {
        return AppRoutes.home;
      }

      // Not authenticated -> allow auth routes, redirect protected routes to login
      if (!hasSession && !isLoginRoute && !isForgotPasswordRoute) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'productDetail',
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '101';
          final id = int.tryParse(idStr) ?? 101;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentCash,
        name: 'paymentCash',
        pageBuilder: (context, state) => _buildSlideUpPage(
          context: context,
          state: state,
          child: CashPaymentScreen(
            checkoutResult: state.extra as CheckoutResult?,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentQris,
        name: 'paymentQris',
        pageBuilder: (context, state) => _buildSlideUpPage(
          context: context,
          state: state,
          child: const QrisPaymentScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        pageBuilder: (context, state) => _buildSlideUpPage(
          context: context,
          state: state,
          child: const PaymentScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'paymentSuccess',
        builder: (context, state) {
          final sale = state.extra as SaleRecord?;
          return PaymentSuccessScreen(saleRecord: sale);
        },
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
});

/// Helper untuk membuat transisi halaman geser mulus dari bawah ke atas (Slide up from bottom).
Page<dynamic> _buildSlideUpPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (disableAnimations) {
    return NoTransitionPage(key: state.pageKey, child: child);
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}
