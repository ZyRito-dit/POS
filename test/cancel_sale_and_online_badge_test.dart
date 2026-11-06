import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_topbar.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/cash_payment_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/transactions_view.dart';

class _FakeTestPosRepository implements PosRepository {
  bool cancelSaleCalled = false;
  int? cancelledSaleId;
  String? cancelReason;

  @override
  Future<(PosConnectivity?, AppFailure?)> pingPos() async {
    return (
      PosConnectivity(
        status: 'ONLINE',
        isOnline: true,
        cashierId: 9,
        cashierName: 'Kasir Outlet 1',
        outletId: 1,
        outletName: 'Kopi Kato - Cabang Sudirman',
        serverTime: DateTime(2026, 11, 5, 14, 57),
        friendlyMessage:
            'Perangkat kasir terhubung secara online ke outlet Kopi Kato - Cabang Sudirman',
      ),
      null,
    );
  }

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async {
    cancelSaleCalled = true;
    cancelledSaleId = saleId;
    cancelReason = reason;
    return (true, 'Transaksi berhasil dibatalkan dan stok dikembalikan', null);
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

  int? lastCheckoutSaleId;
  String? lastCheckoutPaymentMethod;
  int? lastCashReceived;
  bool checkoutCalled = false;

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
    checkoutCalled = true;
    lastCheckoutSaleId = saleId;
    lastCheckoutPaymentMethod = paymentMethod;
    lastCashReceived = cashReceived;
    final total = items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final isPaid = cashReceived != null && cashReceived >= (total > 0 ? total : 18000);
    return (
      CheckoutResult(
        saleId: saleId ?? 7771,
        transactionNo: 'TRX-${saleId ?? 7771}',
        outletName: 'Kopi Kato',
        cashierName: 'Budi Kasir',
        items: items.isNotEmpty
            ? items
                .map((i) => SaleItemRecord(
                      productId: i.product.id,
                      sku: i.product.sku,
                      productName: i.product.name,
                      unitPrice: i.product.basePrice,
                      qty: i.qty,
                    ))
                .toList()
            : const [
                SaleItemRecord(
                  productId: 101,
                  sku: 'KTO-001',
                  productName: 'Kopi Susu Gula Aren',
                  unitPrice: 18000,
                  qty: 1,
                ),
              ],
        subtotal: total > 0 ? total : 18000,
        discountAmount: 0,
        taxAmount: 0,
        totalAmount: total > 0 ? total : 18000,
        paidAmount: cashReceived ?? 0,
        changeAmount: isPaid ? (cashReceived - (total > 0 ? total : 18000)) : 0,
        paymentMethod: paymentMethod,
        paymentStatus: isPaid ? 'PAID' : 'PENDING',
        status: isPaid ? 'COMPLETED' : 'PENDING',
        receiptFormat: receiptFormat,
        createdAt: DateTime.now(),
      ),
      null,
    );
  }

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  }) async =>
      (null, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  }) async =>
      (null, null);

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  }) async =>
      (true, null, null);

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  }) async =>
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
}

void main() {
  group('Online Badge & Cancel Sale Integration Tests', () {
    testWidgets('Online Badge in KatoTopbar reflects online connectivity',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeTestPosRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(70),
                child: KatoTopbar(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Online badge text
      expect(find.text('Online'), findsOneWidget);

      // Tap on the Online badge to re-ping and show snackbar message
      await tester.tap(find.text('Online'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Perangkat kasir terhubung secara online'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TransactionsView: Pending sale has Batalkan Transaksi button, cancels and updates status in history',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeTestPosRepository();

      final pendingSale = SaleRecord(
        id: 9991,
        invoiceNumber: 'INV-PENDING-001',
        terminalCode: 'Kato Sudirman',
        cashierName: 'Kasir 1',
        createdAt: DateTime.now(),
        paymentMethod: PaymentMethod.qris,
        status: TransactionStatus.pending,
        items: const [
          SaleItemRecord(
            productId: 1,
            sku: 'COF-01',
            productName: 'Iced Americano',
            unitPrice: 20000,
            qty: 2,
          ),
        ],
        totalAmount: 40000,
        amountPaid: 0,
        changeAmount: 0,
      );

      final container = ProviderContainer(
        overrides: [
          posRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Seed the pending sale in salesProvider
      container.read(salesProvider.notifier).addSale(pendingSale);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TransactionsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify pending transaction row is rendered
      expect(find.text('INV-PENDING-001'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);

      // Tap on the pending transaction row to open detail card
      await tester.tap(find.text('INV-PENDING-001'));
      await tester.pumpAndSettle();

      // In detail card, verify "Batalkan Transaksi" button is present
      final cancelBtnFinder = find.widgetWithText(
        OutlinedButton,
        'Batalkan Transaksi',
      );
      expect(cancelBtnFinder, findsOneWidget);

      await tester.ensureVisible(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Tap "Batalkan Transaksi"
      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('Batalkan Transaksi?'), findsOneWidget);
      expect(
        find.textContaining('akan dibatalkan. Stok produk yang dipesan akan otomatis dikembalikan'),
        findsOneWidget,
      );

      // Confirm cancellation
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Ya, Batalkan Transaksi');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify cancel API was called with the correct saleId
      expect(fakeRepo.cancelSaleCalled, isTrue);
      expect(fakeRepo.cancelledSaleId, equals(9991));

      // Verify status in history is updated to Cancelled
      expect(find.text('Cancelled'), findsWidgets);

      // Verify success snackbar is shown
      expect(
        find.textContaining('Transaksi berhasil dibatalkan dan stok dikembalikan'),
        findsOneWidget,
      );
    });

    testWidgets(
        'CashPaymentScreen: Batalkan Pembayaran without entering nominal immediately calls cancelSale API',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeTestPosRepository();

      final initialCheckout = CheckoutResult(
        saleId: 8881,
        transactionNo: 'TRX-8881',
        outletName: 'Kopi Kato',
        cashierName: 'Budi Kasir',
        items: const [
          SaleItemRecord(
            productId: 101,
            sku: 'KTO-001',
            productName: 'Kopi Susu Gula Aren',
            unitPrice: 18000,
            qty: 1,
          ),
        ],
        subtotal: 18000,
        discountAmount: 0,
        taxAmount: 0,
        totalAmount: 18000,
        paidAmount: 0,
        changeAmount: 0,
        paymentMethod: 'CASH',
        paymentStatus: 'PENDING',
        status: 'PENDING',
        receiptFormat: 'A',
        createdAt: DateTime(2026, 11, 5, 12, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: CashPaymentScreen(
              checkoutResult: initialCheckout,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify total tagihan is displayed
      expect(find.text('Rp 18.000'), findsWidgets);

      // Verify "Batalkan Pembayaran" button is present and tap it without inputting any cash nominal
      final cancelBtnFinder = find.widgetWithText(
        OutlinedButton,
        'Batalkan Pembayaran',
      );
      expect(cancelBtnFinder, findsOneWidget);

      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Verify cancelSale API was triggered immediately with saleId 8881
      expect(fakeRepo.cancelSaleCalled, isTrue);
      expect(fakeRepo.cancelledSaleId, equals(8881));
    });
  });
}
