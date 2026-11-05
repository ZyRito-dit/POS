import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/repositories/auth_repository_impl.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/auth_repository.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/screens/home/home_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  }) async {
    const user = UserProfile(
      id: 1,
      username: 'admin@katopos.id',
      email: 'admin@katopos.id',
      fullName: 'Superadmin',
      isActive: true,
      role: 'SUPERADMIN',
    );
    return (
      const AuthToken(
        accessToken: 'fake_jwt_token',
        tokenType: 'Bearer',
        user: user,
      ),
      null,
    );
  }

  @override
  Future<(UserProfile?, AppFailure?)> getCurrentUser() async => (null, null);

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
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<(UserProfile?, AppFailure?)> register({
    required String username,
    required String password,
    required String email,
    String? fullName,
  }) async =>
      (null, null);
}

class _FakePosRepository implements PosRepository {
  final PosProduct sampleProduct;

  _FakePosRepository(this.sampleProduct);

  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async {
    return ([sampleProduct], null);
  }

  @override
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({
    int? outletId,
  }) async {
    return (const [
      ProductCategory(id: 0, name: 'Semua'),
      ProductCategory(id: 1, name: 'Makanan'),
    ], null);
  }

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
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  }) async =>
      (null, null);

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  }) async =>
      (true, 'Verified', null);

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  }) async =>
      (true, 'Simulated', null);

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
  Future<(PosConnectivity?, AppFailure?)> pingPos() async =>
      (PosConnectivity.initial(), null);

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async =>
      (true, 'Transaksi berhasil dibatalkan', null);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'Badge stok produk berkurang secara reaktif saat item dimasukkan ke keranjang',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testProduct = PosProduct(
      id: 101,
      sku: 'P001',
      name: 'Coleslaw Salad',
      basePrice: 22000,
      categoryId: 1,
      categoryName: 'Makanan',
      stock: 20,
      description: 'Salad segar',
      packagingInfo: 'Porsi',
      imageUrl: '',
    );

    final fakePosRepo = _FakePosRepository(testProduct);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          posRepositoryProvider.overrideWithValue(fakePosRepo),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi produk tampil dengan stok awal 20 pada badge ungu
    expect(find.text('Coleslaw Salad'), findsOneWidget);
    // Kode produk dinonaktifkan dari tampilan card produk
    // expect(find.text('Kode: P001'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);

    // 2. Klik produk untuk menambahkan ke keranjang -> stok tersisa berkurang menjadi 19
    await tester.tap(find.text('Coleslaw Salad').first);
    await tester.pumpAndSettle();

    expect(find.text('19'), findsOneWidget);
    expect(find.text('20'), findsNothing);

    // 3. Klik lagi -> stok tersisa berkurang menjadi 18
    await tester.tap(find.text('Coleslaw Salad').first);
    await tester.pumpAndSettle();

    expect(find.text('18'), findsOneWidget);
    expect(find.text('19'), findsNothing);

    // 4. Klik tombol hapus item di panel keranjang -> stok kembali menjadi 20
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);
    expect(find.text('18'), findsNothing);
  });
}
