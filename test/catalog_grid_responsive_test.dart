import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_catalog_view.dart';

class _FakePosCatalogRepository implements PosRepository {
  final List<PosProduct> products;
  _FakePosCatalogRepository(this.products);

  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async => (products, null);

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
  }) async => (null, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  }) async => (null, null);

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  }) async => (null, null);

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  }) async => (true, 'Verified', null);

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  }) async => (true, 'Simulated', null);

  @override
  Future<(List<SaleRecord>?, AppFailure?)> getSales({
    int? outletId,
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async => (const <SaleRecord>[], null);

  @override
  Future<(PosConnectivity?, AppFailure?)> pingPos() async =>
      (PosConnectivity.initial(), null);

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async =>
      (true, 'Transaksi berhasil dibatalkan', null);

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
  const sampleProducts = [
    PosProduct(
      id: 1,
      sku: 'COF-01',
      name: 'Iced Coffee Latte',
      basePrice: 24000,
      categoryId: 1,
      categoryName: 'Coffee',
      stock: 20,
      description: 'Latte kopi segar',
      packagingInfo: 'Cup',
      imageUrl: '',
    ),
    PosProduct(
      id: 2,
      sku: 'MAT-02',
      name: 'Iced Matcha Latte',
      basePrice: 26000,
      categoryId: 2,
      categoryName: 'Non-Coffee',
      stock: 15,
      description: 'Matcha latte',
      packagingInfo: 'Cup',
      imageUrl: '',
    ),
    PosProduct(
      id: 3,
      sku: 'AME-03',
      name: 'Iced Americano / Long Black',
      basePrice: 20000,
      categoryId: 1,
      categoryName: 'Coffee',
      stock: 30,
      description: 'Espresso dengan air dingin',
      packagingInfo: 'Cup',
      imageUrl: '',
    ),
    PosProduct(
      id: 4,
      sku: 'CAP-04',
      name: 'Iced Cappuccino',
      basePrice: 25000,
      categoryId: 1,
      categoryName: 'Coffee',
      stock: 12,
      description: 'Cappuccino foam lembut',
      packagingInfo: 'Cup',
      imageUrl: '',
    ),
  ];

  group('KatoCatalogView Responsive Grid Tests', () {
    testWidgets(
      'Tablet Landscape mode (1024x768): Grid renders exactly 4 cards across',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakePosCatalogRepository(sampleProducts);

        // Simulasi lebar layout katalog di landscape tablet dengan cart panel 360px:
        // 1024 - 360 = 664px
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              posRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 664,
                  height: 768,
                  child: KatoCatalogView(isMobile: false),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Temukan GridView dan periksa SliverGridDelegate
        final gridFinder = find.byType(GridView);
        expect(gridFinder, findsOneWidget);

        final gridView = tester.widget<GridView>(gridFinder);
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

        // Harus 4 kolom ke samping sesuai instruksi user
        expect(delegate.crossAxisCount, 4);
        expect(delegate.childAspectRatio, 0.65);

        // 2. Keempat produk harus tampil bersamaan di baris layar tanpa overflow
        expect(find.text('Iced Coffee Latte'), findsOneWidget);
        expect(find.text('Iced Matcha Latte'), findsOneWidget);
        expect(find.text('Iced Americano / Long Black'), findsOneWidget);
        expect(find.text('Iced Cappuccino'), findsOneWidget);

        // 3. Pastikan tidak ada exception RenderFlex overflow
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Mobile Phone mode (390x844): Grid renders 2 cards across responsively',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakePosCatalogRepository(sampleProducts);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              posRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 390,
                  height: 844,
                  child: KatoCatalogView(isMobile: true),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final gridFinder = find.byType(GridView);
        expect(gridFinder, findsOneWidget);

        final gridView = tester.widget<GridView>(gridFinder);
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

        // Mobile portrait harus 2 kolom
        expect(delegate.crossAxisCount, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Search with keyboard open & restricted height (150px total / ~78.9px expanded): Zero RenderFlex overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakePosCatalogRepository(sampleProducts);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              posRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 598.6,
                  height: 150, // Sangat sempit saat keyboard virtual terbuka (tinggi sisa ~78.9px untuk area expanded)
                  child: KatoCatalogView(isMobile: false),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ketik pencarian produk yang tidak ada
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'NonExistentProductXYZ');
        await tester.pumpAndSettle();

        // 2. Pastikan teks "Produk Tidak Ditemukan" muncul dan tidak terjadi overflow
        expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 3. Tekan tombol clear (X) pada search field
        final clearBtn = find.byType(IconButton);
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        // 4. Katalog kembali normal menampilkan produk
        expect(find.text('Iced Coffee Latte'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
