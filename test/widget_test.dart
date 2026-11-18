import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/data/repositories/auth_repository_impl.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/auth_repository.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';
import 'package:pos_apps_umkm/main.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_sidebar.dart';

/// Fake repository autentikasi untuk pengujian hermetis tanpa ketergantungan jaringan eksternal.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  }) async {
    if (email == 'admin@katopos.id' && password.isNotEmpty) {
      const user = UserProfile(
        id: 5,
        username: 'admin@katopos.id',
        email: 'admin@katopos.id',
        fullName: 'Superadmin',
        isActive: true,
        role: 'SUPERADMIN',
      );
      const token = AuthToken(
        accessToken: 'fake_jwt_token',
        tokenType: 'Bearer',
        user: user,
      );
      return (token, null);
    }
    return (null, const InvalidCredentialsFailure('Email atau kata sandi salah.'));
  }

  @override
  Future<(UserProfile?, AppFailure?)> getCurrentUser() async {
    return (
      const UserProfile(
        id: 5,
        username: 'admin@katopos.id',
        email: 'admin@katopos.id',
        fullName: 'Superadmin',
        isActive: true,
        role: 'SUPERADMIN',
      ),
      null,
    );
  }

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<(List<Outlet>?, AppFailure?)> getAccessibleOutlets() async => (
        const [
          Outlet(
            id: 1,
            tenantId: 1,
            code: 'OUT-01',
            name: 'Kato & Co. Sudirman',
          ),
        ],
        null,
      );

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
  }) async {
    return (
      UserProfile(
        id: 2,
        username: username,
        email: email,
        fullName: fullName,
        isActive: true,
        role: 'CASHIER',
      ),
      null,
    );
  }
}

/// Fake repository produk & katalog untuk pengujian hermetis tanpa ketergantungan API backend.
class FakePosRepository implements PosRepository {
  final List<PosProduct> _sampleProducts = const [
    PosProduct(
      id: 1,
      sku: 'KTO-MKN-001',
      name: 'Nasi Kari Ayam',
      basePrice: 35000,
      categoryId: 2,
      categoryName: 'Makanan',
      stock: 20,
      description: 'Nasi kari ayam lezat khas Kato',
      packagingInfo: 'Dine-in / Takeaway',
      imageUrl: '',
    ),
    PosProduct(
      id: 2,
      sku: 'KTO-DST-002',
      name: 'Mille-Feuille / Vanilla Slice',
      basePrice: 45000,
      categoryId: 3,
      categoryName: 'Dessert',
      stock: 15,
      description: 'Pastry renyah dengan krim vanila',
      packagingInfo: 'Box',
      imageUrl: '',
    ),
  ];

  final List<ProductCategory> _sampleCategories = const [
    ProductCategory(id: 1, name: 'Semua Kategori'),
    ProductCategory(id: 2, name: 'Makanan'),
    ProductCategory(id: 3, name: 'Dessert'),
  ];

  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async {
    return (_sampleProducts, null);
  }

  @override
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({
    int? outletId,
  }) async {
    return (_sampleCategories, null);
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
  }) async {
    final total = items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final finalTotal = total > 0 ? total : 25000;
    final isPaid = cashReceived != null && cashReceived >= finalTotal;
    return (
      CheckoutResult(
        saleId: saleId ?? 5001,
        transactionNo: 'TRX-${saleId ?? 5001}',
        outletName: 'Kopi Kato',
        cashierName: 'Kasir',
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
            : const [],
        subtotal: finalTotal,
        discountAmount: 0,
        taxAmount: 0,
        totalAmount: finalTotal,
        paidAmount: cashReceived ?? 0,
        changeAmount: isPaid ? (cashReceived - finalTotal) : 0,
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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'Tablet viewport (1280x800): Light/Dark mode, full-page Product Detail, Payment page, and all menus render without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        posRepositoryProvider.overrideWithValue(FakePosRepository()),
      ],
    );
    addTearDown(container.dispose);

    // Verify Light Mode is default (Mode Putih Utama)
    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NexSellApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang di Kato POS'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);

    // Test Forgot Password navigation & screen content
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi Anda?'), findsOneWidget);
    expect(
      find.text(
        'Silakan hubungi Admin atau Owner outlet Anda untuk melihat atau mengatur ulang kata sandi akun ini.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kembali Masuk'), findsOneWidget);

    // Tap "Kembali Masuk" to return to Login
    await tester.tap(find.text('Kembali Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);

    // Login (test empty input validation first, then enter credentials)
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Silakan masukkan email Anda'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'admin@katopos.id');
    await tester.enterText(find.byType(TextFormField).last, 'nexsell2026');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify Kato POS Kasir screen and dummy products are displayed
    expect(find.text('Kato & Co. Sudirman'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Mille-Feuille / Vanilla Slice'), findsWidgets);
    expect(find.text('Daftar Pesanan'), findsOneWidget);

    // Verify empty cart state matches exact wording and layout
    expect(find.text('Belum ada pesanan.'), findsOneWidget);
    expect(
      find.text('Pilih produk dari katalog di sebelah kiri untuk\nmenambahkan pesanan.'),
      findsOneWidget,
    );

    // Tap product card to add to cart
    await tester.tap(find.text('Nasi Kari Ayam'));
    await tester.pumpAndSettle();

    // Verify Metode Pembayaran and Detail Pembayaran appear, with Discount removed per design directive
    expect(find.text('Metode Pembayaran'), findsOneWidget);
    expect(find.text('Detail Pembayaran'), findsOneWidget);
    expect(find.text('Discount'), findsNothing);

    // Navigate to full-page PaymentScreen via 'Proses Pembayaran'
    expect(find.text('Proses Pembayaran'), findsOneWidget);
    await tester.tap(find.text('Proses Pembayaran'));
    await tester.pumpAndSettle();

    expect(find.text('Total Tagihan'), findsOneWidget);

    // Return back from PaymentScreen to HomeScreen via Batalkan Pembayaran
    await tester.tap(find.text('Batalkan Pembayaran'));
    await tester.pumpAndSettle();

    // Test tablet drawer: Tapping menu button on Topbar opens the full Kato drawer
    await tester.tap(find.byTooltip('Menu Utama'));
    await tester.pumpAndSettle();

    // Verify Drawer is open with KatoSidebar and header/body components (Katalog & Transaksi only)
    expect(find.byType(KatoSidebar), findsOneWidget);
    expect(find.text('Katalog'), findsWidgets);
    expect(find.text('Transaksi'), findsWidgets);
    expect(find.text('Sinkronisasi'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.byTooltip('Tutup Menu'), findsOneWidget);

    // Verify Stok, Pengaturan, and dark mode toggle are removed per design directive
    expect(find.text('Stok'), findsNothing);
    expect(find.text('Pengaturan'), findsNothing);
    expect(find.byTooltip('Mode Gelap'), findsNothing);
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Tap hamburger button in drawer header to close drawer
    await tester.tap(find.byTooltip('Tutup Menu'));
    await tester.pumpAndSettle();

    // Verify drawer is closed and main content is visible
    expect(find.byTooltip('Tutup Menu'), findsNothing);
  });

  testWidgets(
      'Mobile Phone viewport (390x844): All screens, Product Detail page, and tabs render cleanly without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          posRepositoryProvider.overrideWithValue(FakePosRepository()),
        ],
        child: const NexSellApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang di Kato POS'), findsOneWidget);

    // Login on mobile screen
    await tester.enterText(find.byType(TextFormField).first, 'admin@katopos.id');
    await tester.enterText(find.byType(TextFormField).last, 'nexsell2026');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify Kato POS on mobile screen
    expect(find.text('Kato & Co. Sudirman'), findsOneWidget);
    expect(find.text('Mille-Feuille / Vanilla Slice'), findsWidgets);

    // Tap product card to add to cart so the sticky cart bar appears
    await tester.tap(find.text('Mille-Feuille / Vanilla Slice').first);
    await tester.pumpAndSettle();

    // Verify sticky mobile cart bar appears
    expect(find.text('Lihat Pesanan'), findsOneWidget);
    await tester.tap(find.text('Lihat Pesanan'));
    await tester.pumpAndSettle();

    // Modal bottom sheet with KatoCartPanel opens
    expect(find.text('Daftar Pesanan'), findsOneWidget);
    expect(find.text('Proses Pembayaran'), findsOneWidget);
    await tester.tap(find.text('Proses Pembayaran'));
    await tester.pumpAndSettle();

    expect(find.text('Total Tagihan'), findsOneWidget);
    await tester.tap(find.text('Batalkan Pembayaran'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'DevicePreview (device_preview 1.3.1): Successfully wraps NexSellApp and renders device simulation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        posRepositoryProvider.overrideWithValue(FakePosRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      DevicePreview(
        enabled: true,
        builder: (context) => UncontrolledProviderScope(
          container: container,
          child: const NexSellApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify DevicePreview renders the app successfully
    expect(find.byType(DevicePreview), findsOneWidget);
    expect(find.text('Kato POS'), findsWidgets);
  });

  testWidgets(
      'System Bars & Taskbar Insets Test: Tablet with Android 12L/13/14 PC-style Taskbar (64px bottom) and status bar (48px top) renders without content obstruction',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 64, left: 0, right: 0);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        posRepositoryProvider.overrideWithValue(FakePosRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NexSellApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login screen renders with safe insets
    expect(find.text('Selamat datang di Kato POS'), findsOneWidget);

    // Login
    await tester.enterText(find.byType(TextFormField).first, 'admin@katopos.id');
    await tester.enterText(find.byType(TextFormField).last, 'nexsell2026');
    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify on home screen:
    // Topbar text is positioned below status bar (top >= 48)
    final topbarOffset = tester.getTopLeft(find.text('Superadmin'));
    expect(topbarOffset.dy, greaterThanOrEqualTo(48.0));

    // Add item to cart to show the checkout button in the cart panel
    await tester.tap(find.text('Nasi Kari Ayam').first);
    await tester.pumpAndSettle();

    // Cart Panel content / "Proses Pembayaran" button sits strictly above the 64px taskbar (bottom <= 800 - 64 = 736)
    final checkoutBtn = find.text('Proses Pembayaran');
    expect(checkoutBtn, findsOneWidget);
    final checkoutBtnBottom = tester.getBottomRight(checkoutBtn);
    expect(checkoutBtnBottom.dy, lessThanOrEqualTo(800.0 - 64.0));
  });
}
