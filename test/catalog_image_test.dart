import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/models/pos_catalog_dto.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_catalog_view.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

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
  group('POS Catalog Image URL Tests', () {
    test('PosCatalogItemDto parses image_url directly from Swagger response', () {
      final json = {
        'id': 1,
        'sku': 'KATO-KOPI-01',
        'name': 'Es Kopi Susu Kato',
        'description': 'Signature espresso with fresh milk',
        'price': 25000,
        'qty_on_hand': 95,
        'category_id': 1,
        'category_name': 'Coffee & Espresso',
        'track_stock': true,
        'status': 'ACTIVE',
        'outlet_id': 1,
        'image_url': 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38',
      };

      final dto = PosCatalogItemDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.imageUrl, 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38');

      final entity = dto.toEntity();
      expect(entity.imageUrl, 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38');
    });

    test('normalizeImageUrl replaces localhost and 127.0.0.1 MinIO URLs with backend host', () {
      const localhostUrl = 'http://localhost:9000/katopos/products/kopi.jpg';
      final host = Uri.parse(AppConstants.baseUrl).host;
      final normalized = PosCatalogItemDto.normalizeImageUrl(localhostUrl);
      expect(normalized, contains('$host:9000'));
      expect(normalized, isNot(contains('localhost')));

      const ipUrl = 'http://127.0.0.1:9000/katopos/products/kopi.jpg';
      final normalizedIp = PosCatalogItemDto.normalizeImageUrl(ipUrl);
      expect(normalizedIp, contains('$host:9000'));
      expect(normalizedIp, isNot(contains('127.0.0.1')));
    });

    test('normalizeImageUrl prefixes relative upload paths with backend origin', () {
      const relativePath = '/uploads/products/macchiato.png';
      final normalized = PosCatalogItemDto.normalizeImageUrl(relativePath);
      expect(normalized, startsWith(AppConstants.baseUrl));
      expect(normalized, endsWith('/uploads/products/macchiato.png'));
    });

    test('PosCatalogItemDto keeps imageUrl empty when null in backend model', () {
      final jsonNullImage = {
        'id': 2,
        'sku': 'KATO-KOPI-02',
        'name': 'Produk Tanpa Foto',
        'price': 20000,
        'qty_on_hand': 10,
        'category_id': 1,
        'category_name': 'Coffee',
        'track_stock': true,
        'status': 'ACTIVE',
        'outlet_id': 1,
        'image_url': null,
      };

      final dto = PosCatalogItemDto.fromJson(jsonNullImage);
      expect(dto.imageUrl, isNull);

      final entity = dto.toEntity();
      expect(entity.imageUrl, isEmpty);
    });

    testWidgets('ProductNoImagePlaceholder renders standard image icon cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductNoImagePlaceholder(iconSize: 36),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('ProductNetworkImage renders ProductNoImagePlaceholder when imageUrl is empty',
        (tester) async {
      const productNoImage = PosProduct(
        id: 99,
        sku: 'TEST-SKU',
        name: 'Item Tanpa Gambar',
        basePrice: 20000,
        categoryId: 1,
        categoryName: 'Minuman',
        stock: 10,
        description: 'Test Description',
        packagingInfo: 'Cup',
        imageUrl: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductNetworkImage(
              product: productNoImage,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Verify no Image.network crash, standard uniform placeholder rendered
      expect(find.byType(ProductNoImagePlaceholder), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets(
        'KatoCatalogView renders without any RenderFlex overflow on narrow tablet & mobile viewports',
        (tester) async {
      tester.view.physicalSize = const Size(998, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const sampleProducts = [
        PosProduct(
          id: 1,
          sku: 'KTO-01',
          name: 'Nasi Kari Ayam Spesial Komplit Dengan Sayur',
          basePrice: 35000,
          categoryId: 1,
          categoryName: 'Makanan',
          stock: 20,
          description: 'Deskripsi',
          packagingInfo: 'Box',
          imageUrl: '',
        ),
        PosProduct(
          id: 2,
          sku: 'KTO-02',
          name: 'Es Teh Manis',
          basePrice: 5000,
          categoryId: 2,
          categoryName: 'Minuman',
          stock: 50,
          description: 'Deskripsi',
          packagingInfo: 'Cup',
          imageUrl: '',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          posRepositoryProvider.overrideWithValue(
            _FakePosCatalogRepository(sampleProducts),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: KatoCatalogView(isMobile: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both products rendered with zero layout overflow exceptions
      expect(find.text('Nasi Kari Ayam Spesial Komplit Dengan Sayur'), findsOneWidget);
      expect(find.text('Es Teh Manis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
