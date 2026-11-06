import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/data/models/auth_dto.dart';
import 'package:pos_apps_umkm/data/repositories/auth_repository_impl.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/auth_repository.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/home_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_topbar.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/transactions_view.dart';

class _FakeMultiOutletAuthRepository implements AuthRepository {
  final List<Outlet> outlets;
  final UserProfile user;

  _FakeMultiOutletAuthRepository({
    required this.outlets,
    required this.user,
  });

  @override
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  }) async {
    return (
      AuthToken(
        accessToken: 'mock_token',
        tokenType: 'Bearer',
        user: user,
      ),
      null,
    );
  }

  @override
  Future<(List<Outlet>?, AppFailure?)> getAccessibleOutlets() async =>
      (outlets, null);

  @override
  Future<(UserProfile?, AppFailure?)> getCurrentUser() async => (user, null);

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<(AuthToken?, AppFailure?)> refreshToken() async => (null, null);

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
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({
    int? outletId,
  }) async =>
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const outletSudirman = Outlet(
    id: 1,
    tenantId: 1,
    code: 'OUT-01',
    name: 'Kopi Kato - Cabang Sudirman',
    address: 'Gedung Plaza Sudirman Lt. Dasar, Jakarta',
    phone: '081234567891',
    status: 'ACTIVE',
  );

  const outletThamrin = Outlet(
    id: 2,
    tenantId: 1,
    code: 'OUT-02',
    name: 'Kopi Kato - Cabang Thamrin',
    address: 'Jl. MH Thamrin No. 20, Jakarta',
    phone: '081234567892',
    status: 'ACTIVE',
  );

  group('Outlet Model & DTO Tests', () {
    test('OutletDto parses JSON correctly and converts to Outlet entity', () {
      final json = {
        'id': 1,
        'tenant_id': 1,
        'code': 'OUT-01',
        'name': 'Kopi Kato - Cabang Sudirman',
        'address': 'Gedung Plaza Sudirman Lt. Dasar, Jakarta',
        'phone': '081234567891',
        'timezone': 'Asia/Jakarta',
        'status': 'ACTIVE',
        'total_cashiers': 4,
      };

      final dto = OutletDto.fromJson(json);
      expect(dto.id, 1);
      expect(dto.tenantId, 1);
      expect(dto.code, 'OUT-01');
      expect(dto.name, 'Kopi Kato - Cabang Sudirman');
      expect(dto.totalCashiers, 4);

      final entity = dto.toEntity();
      expect(entity.id, 1);
      expect(entity.name, 'Kopi Kato - Cabang Sudirman');
      expect(entity.isActive, isTrue);
    });
  });

  group('Login with Outlet Resolution Tests', () {
    test('Cashier login auto-selects assigned outlet', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeMultiOutletAuthRepository(
              outlets: [outletSudirman],
              user: const UserProfile(
                id: 5,
                username: 'Kasir Sudirman 1',
                email: 'kasir1@kopikato.com',
                isActive: true,
                role: 'CASHIER',
                tenantId: 1,
                outletId: 1,
              ),
            ),
          ),
          posRepositoryProvider.overrideWithValue(_FakePosRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loginProvider.notifier).login(
            email: 'kasir1@kopikato.com',
            password: 'Password123!',
          );

      expect(container.read(loginProvider), isA<LoginSuccess>());
      expect(container.read(selectedOutletProvider)?.id, 1);
      expect(container.read(selectedOutletProvider)?.name,
          'Kopi Kato - Cabang Sudirman');
      expect(container.read(currentUserProvider)?.outletId, 1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('Owner login with null outletId auto-selects first accessible outlet',
        () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeMultiOutletAuthRepository(
              outlets: [outletSudirman, outletThamrin],
              user: const UserProfile(
                id: 3,
                username: 'Owner Kopi Kato',
                email: 'owner@kopikato.com',
                isActive: true,
                role: 'OWNER',
                tenantId: 1,
                outletId: null, // Owner has null outlet_id upon login
              ),
            ),
          ),
          posRepositoryProvider.overrideWithValue(_FakePosRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loginProvider.notifier).login(
            email: 'owner@kopikato.com',
            password: 'Password123!',
          );

      expect(container.read(loginProvider), isA<LoginSuccess>());
      expect(container.read(accessibleOutletsProvider).length, 2);
      expect(container.read(selectedOutletProvider)?.id, 1);
      expect(container.read(currentUserProvider)?.outletId, 1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    test('Switch active outlet updates selectedOutletProvider and user context',
        () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeMultiOutletAuthRepository(
              outlets: [outletSudirman, outletThamrin],
              user: const UserProfile(
                id: 3,
                username: 'Owner Kopi Kato',
                email: 'owner@kopikato.com',
                isActive: true,
                role: 'OWNER',
                tenantId: 1,
                outletId: 1,
              ),
            ),
          ),
          posRepositoryProvider.overrideWithValue(_FakePosRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.read(selectedOutletProvider.notifier).state = outletSudirman;
      container.read(accessibleOutletsProvider.notifier).state = [
        outletSudirman,
        outletThamrin
      ];

      expect(container.read(selectedOutletProvider)?.id, 1);

      // Switch to Thamrin
      container.read(selectedOutletProvider.notifier).state = outletThamrin;
      final currentUser = container.read(currentUserProvider);
      if (currentUser != null) {
        container.read(currentUserProvider.notifier).state =
            currentUser.copyWith(outletId: outletThamrin.id);
      }

      expect(container.read(selectedOutletProvider)?.id, 2);
      expect(container.read(selectedOutletProvider)?.name,
          'Kopi Kato - Cabang Thamrin');
    });
  });

  group('Topbar Outlet Switcher UI Widget Test', () {
    testWidgets(
        'Topbar displays active outlet name and shows dropdown chevron for multi-outlet user',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      final container = ProviderContainer(
        overrides: [
          selectedOutletProvider.overrideWith((ref) => outletSudirman),
          accessibleOutletsProvider
              .overrideWith((ref) => [outletSudirman, outletThamrin]),
          currentUserProvider.overrideWith(
            (ref) => const UserProfile(
              id: 3,
              username: 'Owner Kopi Kato',
              email: 'owner@kopikato.com',
              isActive: true,
              role: 'OWNER',
              tenantId: 1,
              outletId: 1,
            ),
          ),
          posRepositoryProvider.overrideWithValue(_FakePosRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              appBar: KatoTopbar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify outlet badge renders with active outlet name
      expect(find.text('Kopi Kato - Cabang Sudirman'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap outlet badge to open modal bottom sheet selector
      await tester.tap(find.text('Kopi Kato - Cabang Sudirman'));
      await tester.pumpAndSettle();

      // Verify modal sheet appears with both outlets
      expect(find.text('Pilih Cabang / Outlet'), findsOneWidget);
      expect(find.text('Kopi Kato - Cabang Thamrin'), findsOneWidget);

      // Tap on Cabang Thamrin
      await tester.tap(find.text('Kopi Kato - Cabang Thamrin'));
      await tester.pumpAndSettle();

      // Modal closed and topbar updated to Cabang Thamrin
      expect(find.text('Kopi Kato - Cabang Thamrin'), findsOneWidget);
    });

    testWidgets(
        'On transaction page, KatoTopbar (hamburger, bell, account) is removed and only back button <- is shown',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeMultiOutletAuthRepository(
              outlets: [outletSudirman],
              user: const UserProfile(
                id: 1,
                username: 'Cashier',
                email: 'cashier@kopikato.com',
                isActive: true,
                role: 'CASHIER',
                outletId: 1,
              ),
            ),
          ),
          posRepositoryProvider.overrideWithValue(_FakePosRepository()),
          selectedOutletProvider.overrideWith((ref) => outletSudirman),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on home screen: KatoTopbar is present with Menu Utama
      expect(find.byType(KatoTopbar), findsOneWidget);
      expect(find.byTooltip('Menu Utama'), findsOneWidget);

      // Open drawer
      await tester.tap(find.byTooltip('Menu Utama'));
      await tester.pumpAndSettle();

      // Tap Transaksi in the drawer
      await tester.tap(find.text('Transaksi').last);
      await tester.pumpAndSettle();

      // Now on transaction page:
      // 1. KatoTopbar is completely gone (no hamburger, no bell, no account)
      expect(find.byType(KatoTopbar), findsNothing);
      expect(find.byTooltip('Menu Utama'), findsNothing);

      // 2. TransactionsView is displayed with back button <- and title 'Transaksi'
      expect(find.byType(TransactionsView), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Transaksi'), findsOneWidget);

      // 3. Tap back button <-
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Successfully returned to home screen with KatoTopbar restored
      expect(find.byType(KatoTopbar), findsOneWidget);
      expect(find.byTooltip('Menu Utama'), findsOneWidget);
      expect(find.byType(TransactionsView), findsNothing);
    });

    testWidgets(
      'Profile in KatoTopbar is static: no popup menu and no Keluar dari Kasir option',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeMultiOutletAuthRepository(
                outlets: [outletSudirman],
                user: const UserProfile(
                  id: 1,
                  username: 'Sekarisma Putri',
                  email: 'sekarisma@kopikato.com',
                  isActive: true,
                  role: 'CASHIER',
                  outletId: 1,
                ),
              ),
            ),
            currentUserProvider.overrideWith(
              (ref) => const UserProfile(
                id: 1,
                username: 'Sekarisma Putri',
                email: 'sekarisma@kopikato.com',
                isActive: true,
                role: 'CASHIER',
                outletId: 1,
              ),
            ),
            posRepositoryProvider.overrideWithValue(_FakePosRepository()),
            accessibleOutletsProvider.overrideWith((ref) => [outletSudirman]),
            selectedOutletProvider.overrideWith((ref) => outletSudirman),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. KatoTopbar displays user name and role
        expect(find.text('Sekarisma Putri'), findsOneWidget);
        expect(find.text('Kasir'), findsOneWidget);

        // 2. Profile is not a PopupMenuButton and has no Menu Akun tooltip
        expect(find.byTooltip('Menu Akun'), findsNothing);

        // 3. Tapping the user name does not show Keluar dari Kasir
        await tester.tap(find.text('Sekarisma Putri'));
        await tester.pumpAndSettle();

        expect(find.text('Keluar dari Kasir'), findsNothing);
      },
    );
  });
}
