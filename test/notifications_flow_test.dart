import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/models/notification_dto.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_notifications_modal.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_topbar.dart';

class _FakeNotificationPosRepository implements PosRepository {
  List<SystemNotification> notifications;
  int unreadCount;
  bool markSingleCalled = false;
  int? markedId;
  bool markAllCalled = false;

  _FakeNotificationPosRepository({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  Future<((List<SystemNotification>, int)?, AppFailure?)> getNotifications({
    bool? isRead,
    int page = 1,
    int perPage = 20,
  }) async {
    final list = isRead != null
        ? notifications.where((n) => n.isRead == isRead).toList()
        : notifications;
    return ((list, unreadCount), null);
  }

  @override
  Future<(bool, AppFailure?)> markNotificationAsRead({required int id}) async {
    markSingleCalled = true;
    markedId = id;
    notifications = [
      for (final n in notifications)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    if (unreadCount > 0) unreadCount--;
    return (true, null);
  }

  @override
  Future<(bool, AppFailure?)> markAllNotificationsAsRead() async {
    markAllCalled = true;
    notifications = [for (final n in notifications) n.copyWith(isRead: true)];
    unreadCount = 0;
    return (true, null);
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
  Future<(PosConnectivity?, AppFailure?)> pingPos() async =>
      (PosConnectivity.initial(), null);

  @override
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  }) async =>
      (true, 'Dibatalkan', null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notifications DTO & Parser Tests', () {
    test('NotificationListResponseDto parses Swagger JSON accurately', () {
      final swaggerJson = {
        'success': true,
        'message': 'OK',
        'data': {
          'items': [
            {
              'id': 101,
              'title': 'Pembayaran QRIS Berhasil',
              'message':
                  'Pembayaran QRIS sebesar Rp 25.000 untuk transaksi TRX-001 telah diterima.',
              'type': 'PAYMENT_SUCCESS',
              'reference_type': 'PAYMENT',
              'reference_id': 501,
              'is_read': false,
              'read_at': null,
              'created_at': '2026-11-10T09:30:00Z',
            },
            {
              'id': 102,
              'title': 'Stok Menipis',
              'message': 'Stok Kopi Susu sisa 2 porsi.',
              'type': 'STOCK_ALERT',
              'reference_type': 'PRODUCT',
              'reference_id': 1,
              'is_read': true,
              'read_at': '2026-11-10T09:35:00Z',
              'created_at': '2026-11-10T09:20:00Z',
            }
          ],
          'unread_count': 1,
        },
        'meta': {
          'page': 1,
          'per_page': 20,
          'total': 2,
          'total_pages': 1,
        }
      };

      final dto = NotificationListResponseDto.fromJson(swaggerJson);
      expect(dto.unreadCount, 1);
      expect(dto.items.length, 2);

      final item1 = dto.items[0].toEntity();
      expect(item1.id, 101);
      expect(item1.title, 'Pembayaran QRIS Berhasil');
      expect(item1.isRead, false);
      expect(item1.severity, NotificationSeverity.success);
      expect(item1.type, 'PAYMENT_SUCCESS');
      expect(item1.referenceId, 501);

      final item2 = dto.items[1].toEntity();
      expect(item2.id, 102);
      expect(item2.isRead, true);
      expect(item2.severity, NotificationSeverity.warning);
    });
  });

  group('Topbar Notification Bell & Modal Integration Tests', () {
    testWidgets(
        'Topbar shows unread badge counter and opens modal on click',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleNotifications = [
        SystemNotification(
          id: 1,
          title: 'Pembayaran QRIS Berhasil',
          message: 'Pembayaran Rp 50.000 sukses diterima.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          severity: NotificationSeverity.success,
          type: 'PAYMENT_SUCCESS',
        ),
        SystemNotification(
          id: 2,
          title: 'Peringatan Stok',
          message: 'Stok Espresso hampir habis.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          severity: NotificationSeverity.warning,
          type: 'STOCK_ALERT',
        ),
        SystemNotification(
          id: 3,
          title: 'Info Sistem',
          message: 'Sistem POS telah diperbarui ke versi terbaru.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          severity: NotificationSeverity.info,
          type: 'SYSTEM_INFO',
        ),
      ];

      final fakeRepo = _FakeNotificationPosRepository(
        notifications: sampleNotifications,
        unreadCount: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            currentUserProvider.overrideWith((ref) => const UserProfile(
                  id: 1,
                  username: 'kasir1',
                  fullName: 'Samantha Putri',
                  isActive: true,
                  role: 'CASHIER',
                )),
            selectedOutletProvider.overrideWith((ref) => const Outlet(
                  id: 1,
                  tenantId: 1,
                  code: 'OUT-01',
                  name: 'Kopi Kato - Cabang Sudirman',
                )),
            accessibleOutletsProvider.overrideWith((ref) => const [
                  Outlet(
                    id: 1,
                    tenantId: 1,
                    code: 'OUT-01',
                    name: 'Kopi Kato - Cabang Sudirman',
                  ),
                ]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: KatoTopbar(isMobile: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Topbar renders badge '2' for unread notifications
      expect(find.text('2'), findsOneWidget);

      // Find the notification bell button and tap it
      final bellButton = find.byKey(const Key('topbar_notification_bell'));
      await tester.tap(bellButton);
      await tester.pumpAndSettle();

      // Assert: Modal opened
      expect(find.byType(KatoNotificationsModal), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('2 Baru'), findsOneWidget);
      expect(find.text('Pembayaran QRIS Berhasil'), findsOneWidget);
      expect(find.text('Peringatan Stok'), findsOneWidget);

      // Tap "Tandai Dibaca" button in modal
      final markAllButton = find.byKey(const Key('mark_all_read_button'));
      expect(markAllButton, findsOneWidget);
      await tester.ensureVisible(markAllButton);
      await tester.tap(markAllButton);
      await tester.pumpAndSettle();

      // Verify that markAll was called on fake repository
      expect(fakeRepo.markAllCalled, isTrue);

      // Close modal
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.byType(KatoNotificationsModal), findsNothing);
    });

    testWidgets(
        'Mobile view: Bell badge is positioned at upper-right shoulder and does NOT cover the bell icon',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeNotificationPosRepository(
        notifications: [
          SystemNotification(
            id: 1,
            title: 'Pembayaran QRIS Berhasil',
            message: 'Pelanggan telah membayar',
            createdAt: DateTime.now(),
            isRead: false,
            severity: NotificationSeverity.info,
            type: 'PAYMENT',
          ),
        ],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            unreadNotificationsCountStateProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: KatoTopbar(isMobile: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bellButton = find.byKey(const Key('topbar_notification_bell'));
      expect(bellButton, findsOneWidget);

      final badgeTextFinder =
          find.descendant(of: bellButton, matching: find.text('1'));
      expect(badgeTextFinder, findsOneWidget);

      final bellSvgFinder =
          find.descendant(of: bellButton, matching: find.byType(SvgPicture));
      expect(bellSvgFinder, findsOneWidget);

      final badgeCenter = tester.getCenter(badgeTextFinder);
      final bellCenter = tester.getCenter(bellSvgFinder);

      // Verify the badge center is shifted significantly to the upper-right shoulder
      expect(badgeCenter.dx, greaterThan(bellCenter.dx + 4));
      expect(badgeCenter.dy, lessThan(bellCenter.dy - 4));
    });

    testWidgets(
        'Tablet view: Bell badge is positioned at upper-right shoulder and does NOT cover the bell icon',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeNotificationPosRepository(
        notifications: [
          SystemNotification(
            id: 1,
            title: 'Pembayaran QRIS Berhasil',
            message: 'Pelanggan telah membayar',
            createdAt: DateTime.now(),
            isRead: false,
            severity: NotificationSeverity.info,
            type: 'PAYMENT',
          ),
        ],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            posRepositoryProvider.overrideWithValue(fakeRepo),
            unreadNotificationsCountStateProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: KatoTopbar(isMobile: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final bellButton = find.byKey(const Key('topbar_notification_bell'));
      expect(bellButton, findsOneWidget);

      final badgeTextFinder =
          find.descendant(of: bellButton, matching: find.text('1'));
      expect(badgeTextFinder, findsOneWidget);

      final bellSvgFinder =
          find.descendant(of: bellButton, matching: find.byType(SvgPicture));
      expect(bellSvgFinder, findsOneWidget);

      final badgeCenter = tester.getCenter(badgeTextFinder);
      final bellCenter = tester.getCenter(bellSvgFinder);

      // Verify the badge center is shifted to the upper-right shoulder on tablet as well
      expect(badgeCenter.dx, greaterThan(bellCenter.dx + 4));
      expect(badgeCenter.dy, lessThan(bellCenter.dy - 4));
    });
  });
}
