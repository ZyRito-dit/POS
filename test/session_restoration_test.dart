import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/repositories/auth_repository_impl.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/auth_repository.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/main.dart';

class _FakeSessionAuthRepository implements AuthRepository {
  bool hasSession;
  bool refreshTokenCalled = false;
  bool logoutCalled = false;
  bool returnUnauthorizedOnMe;

  _FakeSessionAuthRepository({
    this.hasSession = true,
    this.returnUnauthorizedOnMe = false,
  });

  @override
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  }) async {
    const user = UserProfile(
      id: 10,
      username: 'kasir_kato',
      email: 'kasir@katopos.id',
      fullName: 'Kasir Kato',
      isActive: true,
      role: 'CASHIER',
      outletId: 1,
    );
    return (
      const AuthToken(
        accessToken: 'valid_access_token',
        tokenType: 'Bearer',
        refreshToken: 'valid_refresh_token',
        user: user,
      ),
      null,
    );
  }

  @override
  Future<(UserProfile?, AppFailure?)> getCurrentUser() async {
    if (returnUnauthorizedOnMe) {
      return (null, const UnauthorizedFailure('Token kadaluarsa.'));
    }
    return (
      const UserProfile(
        id: 10,
        username: 'kasir_kato',
        email: 'kasir@katopos.id',
        fullName: 'Kasir Kato',
        isActive: true,
        role: 'CASHIER',
        outletId: 1,
      ),
      null,
    );
  }

  @override
  Future<(List<Outlet>?, AppFailure?)> getAccessibleOutlets() async => (
        const [
          Outlet(
            id: 1,
            tenantId: 1,
            code: 'OUT-01',
            name: 'Kopi Kato - Cabang Sudirman',
          ),
        ],
        null,
      );

  @override
  Future<bool> hasValidSession() async => hasSession;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    hasSession = false;
  }

  @override
  Future<(AuthToken?, AppFailure?)> refreshToken() async {
    refreshTokenCalled = true;
    returnUnauthorizedOnMe = false;
    return (
      const AuthToken(
        accessToken: 'new_refreshed_access_token',
        tokenType: 'Bearer',
        refreshToken: 'new_refresh_token',
      ),
      null,
    );
  }

  @override
  Future<(UserProfile?, AppFailure?)> register({
    required String username,
    required String password,
    required String email,
    String? fullName,
  }) async =>
      (null, null);
}

class _FakeSessionPosRepository implements PosRepository {
  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async =>
      (
        const [
          PosProduct(
            id: 1,
            outletId: 1,
            name: 'Kopi Susu Gula Aren',
            sku: 'KTO-001',
            basePrice: 18000,
            categoryId: 1,
            categoryName: 'Semua',
            stock: 25,
            description: '',
            packagingInfo: '',
            imageUrl: '',
          ),
        ],
        null,
      );

  @override
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({int? outletId}) async =>
      (const [ProductCategory(id: 1, name: 'Semua')], null);

  @override
  Future<(CheckoutResult?, AppFailure?)> checkout({
    int? saleId,
    required int outletId,
    required String paymentMethod,
    int? cashReceived,
    required List<CartItem> items,
    String receiptFormat = 'A',
    String? idempotencyKey,
  }) async =>
      (null, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  }) async =>
      (null, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({required int paymentId}) async =>
      (null, null);

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({required int paymentId}) async =>
      (true, null, null);

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({required int paymentId}) async =>
      (true, null, null);

  @override
  Future<(List<SaleRecord>?, AppFailure?)> getSales({
    int? outletId,
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async =>
      (const <SaleRecord>[], null);

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async =>
      (true, 'Dibatalkan', null);

  @override
  Future<(PosConnectivity?, AppFailure?)> pingPos() async => (
        PosConnectivity(
          status: 'ONLINE',
          isOnline: true,
          cashierId: 10,
          cashierName: 'Kasir Kato',
          outletId: 1,
          outletName: 'Kopi Kato - Cabang Sudirman',
          serverTime: DateTime.now(),
          friendlyMessage: 'Online',
        ),
        null,
      );

  @override
  Future<((List<SystemNotification>, int)?, AppFailure?)> getNotifications({
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async =>
      ((<SystemNotification>[], 0), null);

  @override
  Future<(bool, AppFailure?)> markNotificationAsRead({required int id}) async =>
      (true, null);

  @override
  Future<(bool, AppFailure?)> markAllNotificationsAsRead() async =>
      (true, null);
}

void main() {
  group('Auto-Login & Session Persistence Tests', () {
    testWidgets(
        'Auto-Login: when valid token exists, opening app automatically navigates to HomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = _FakeSessionAuthRepository(hasSession: true);
      final fakePos = _FakeSessionPosRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            posRepositoryProvider.overrideWithValue(fakePos),
          ],
          child: const NexSellApp(),
        ),
      );

      // Settle splash / session init future
      await tester.pumpAndSettle();

      // Should automatically be on HomeScreen, showing Kato POS catalog
      expect(find.text('Kopi Kato - Cabang Sudirman'), findsWidgets);
      expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
      // Login screen should not be present
      expect(find.text('Selamat datang di Kato POS'), findsNothing);
    });

    testWidgets(
        'Session Expired: when token is expired (401), triggers refreshToken and restores session',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = _FakeSessionAuthRepository(
        hasSession: true,
        returnUnauthorizedOnMe: true,
      );
      final fakePos = _FakeSessionPosRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            posRepositoryProvider.overrideWithValue(fakePos),
          ],
          child: const NexSellApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Refresh token should have been called automatically
      expect(fakeAuth.refreshTokenCalled, isTrue);

      // Should still land successfully on HomeScreen
      expect(find.text('Kopi Kato - Cabang Sudirman'), findsWidgets);
      expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
    });

    testWidgets(
        'No Session: when no token exists, opening app lands cleanly on LoginScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = _FakeSessionAuthRepository(hasSession: false);
      final fakePos = _FakeSessionPosRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            posRepositoryProvider.overrideWithValue(fakePos),
          ],
          child: const NexSellApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Login form should be displayed
      expect(find.text('Selamat datang di Kato POS'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });
  });
}
