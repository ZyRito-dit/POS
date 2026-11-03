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
        builder: (context, state) => const CashPaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentQris,
        name: 'paymentQris',
        builder: (context, state) => const QrisPaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        builder: (context, state) => const PaymentScreen(),
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
