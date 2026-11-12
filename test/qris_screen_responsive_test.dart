import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/qris_payment_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/qris_code_display.dart';

class _FakeQrisErrorPosRepository implements PosRepository {
  final String errorMessage;
  bool cancelCalled = false;

  _FakeQrisErrorPosRepository(this.errorMessage);

  @override
  Future<(PosConnectivity?, AppFailure?)> pingPos() async => (null, null);

  @override
  Future<(CheckoutResult?, AppFailure?)> checkout({
    int? saleId,
    required int outletId,
    required String paymentMethod,
    int? cashReceived,
    required List<CartItem> items,
    String receiptFormat = 'A',
    String? idempotencyKey,
  }) async {
    final result = CheckoutResult(
      saleId: 99,
      transactionNo: 'TRX-TEST-01',
      outletName: 'Kopi Kato',
      cashierName: 'Kasir',
      status: 'PENDING',
      paymentStatus: 'UNPAID',
      paymentMethod: 'QRIS',
      totalAmount: 1,
      paidAmount: 0,
      changeAmount: 0,
      discountAmount: 0,
      taxAmount: 0,
      subtotal: 1,
      receiptFormat: 'A',
      createdAt: DateTime.now(),
      items: const [],
    );
    return (result, null);
  }

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  }) async {
    return (null, ServerFailure(errorMessage));
  }

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async {
    cancelCalled = true;
    return (true, 'Cancelled', null);
  }

  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async =>
      (const <PosProduct>[], null);

  @override
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({int? outletId}) async =>
      (const <ProductCategory>[], null);

  @override
  Future<((List<SystemNotification>, int)?, AppFailure?)> getNotifications({
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async =>
      ((const <SystemNotification>[], 0), null);

  @override
  Future<(bool, AppFailure?)> markNotificationAsRead({required int id}) async =>
      (true, null);

  @override
  Future<(bool, AppFailure?)> markAllNotificationsAsRead() async => (true, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  }) async =>
      (null, null);

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  }) async =>
      (true, null, null);

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  }) async =>
      (false, null, null);

  @override
  Future<(List<SaleRecord>?, AppFailure?)> getSales({
    int? outletId,
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 50,
  }) async =>
      (const <SaleRecord>[], null);
}

class _TestCartNotifier extends CartNotifier {
  final PosProduct product;
  _TestCartNotifier(this.product);

  @override
  List<CartItem> build() => [CartItem(product: product, qty: 1)];
}

void main() {
  const longBackendError =
      'gagal menghasilkan QRIS melalui provider: xendit api error (HTTP 400): Failed to validate the request, 2 errors occurred.';

  const sampleProduct = PosProduct(
    id: 1,
    sku: 'SKU-001',
    name: 'Beef Yakiniku Rice Bowl',
    basePrice: 1,
    categoryId: 1,
    categoryName: 'Food',
    stock: 10,
    description: '',
    packagingInfo: '',
    imageUrl: '',
  );

  group('QrisPaymentScreen Responsive & Anti-Overflow Tests', () {
    testWidgets(
        'Phone Landscape (844x360): Side-by-Side layout with long error text renders with ZERO overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(844, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeQrisErrorPosRepository(longBackendError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            cartProvider.overrideWith(() => _TestCartNotifier(sampleProduct)),
            currentUserProvider.overrideWith((ref) => const UserProfile(
                  id: 1,
                  username: 'kasir1',
                  fullName: 'Kasir Outlet 1',
                  isActive: true,
                  role: 'CASHIER',
                )),
            selectedOutletProvider.overrideWith((ref) => const Outlet(
                  id: 1,
                  tenantId: 1,
                  code: 'OUT-01',
                  name: 'Kopi Kato - Cabang Sudirman',
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QrisPaymentScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero exceptions / zero RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Verify side-by-side elements are rendered
      expect(find.byType(QrisCodeDisplay), findsOneWidget);
      expect(find.text('Kato POS System'), findsOneWidget);
      expect(find.text('Total Tagihan'), findsOneWidget);
      expect(find.text('Rp 1'), findsOneWidget);
      expect(find.text('Batalkan Pembayaran'), findsOneWidget);

      // Verify error text is present and wrapped cleanly
      expect(find.textContaining('gagal menghasilkan QRIS'), findsOneWidget);

      // Tap Batalkan Pembayaran
      await tester.tap(find.text('Batalkan Pembayaran'));
      await tester.pumpAndSettle();
      expect(fakeRepo.cancelCalled, isTrue);
    });

    testWidgets(
        'Phone Portrait (390x844): Vertical layout with long error text renders with ZERO overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeQrisErrorPosRepository(longBackendError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            cartProvider.overrideWith(() => _TestCartNotifier(sampleProduct)),
            currentUserProvider.overrideWith((ref) => const UserProfile(
                  id: 1,
                  username: 'kasir1',
                  fullName: 'Kasir Outlet 1',
                  isActive: true,
                  role: 'CASHIER',
                )),
            selectedOutletProvider.overrideWith((ref) => const Outlet(
                  id: 1,
                  tenantId: 1,
                  code: 'OUT-01',
                  name: 'Kopi Kato - Cabang Sudirman',
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QrisPaymentScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero exceptions / zero RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Elements rendered in portrait
      expect(find.byType(QrisCodeDisplay), findsOneWidget);
      expect(find.text('Kato POS System'), findsOneWidget);
      expect(find.text('Total Tagihan'), findsOneWidget);
      expect(find.text('Rp 1'), findsOneWidget);
      expect(find.text('Batalkan Pembayaran'), findsOneWidget);
      expect(find.textContaining('gagal menghasilkan QRIS'), findsOneWidget);
    });

    testWidgets(
        'Tablet Viewport (1194x834): Standard layout with error text renders cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeQrisErrorPosRepository(longBackendError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            cartProvider.overrideWith(() => _TestCartNotifier(sampleProduct)),
            currentUserProvider.overrideWith((ref) => const UserProfile(
                  id: 1,
                  username: 'kasir1',
                  fullName: 'Kasir Outlet 1',
                  isActive: true,
                  role: 'CASHIER',
                )),
            selectedOutletProvider.overrideWith((ref) => const Outlet(
                  id: 1,
                  tenantId: 1,
                  code: 'OUT-01',
                  name: 'Kopi Kato - Cabang Sudirman',
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QrisPaymentScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero exceptions / zero RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(QrisCodeDisplay), findsOneWidget);
      expect(find.text('Kato POS System'), findsOneWidget);
      expect(find.text('Total Tagihan'), findsOneWidget);
      expect(find.text('Rp 1'), findsOneWidget);
      expect(find.text('Batalkan Pembayaran'), findsOneWidget);
    });
  });
}
