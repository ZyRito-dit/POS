import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/data/dummy/pos_dummy_data.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';

/// Active navigation tab index on the main POS screen.
final activePosTabProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Catalog & Products State (Diambil dari API Kato POS: /api/v1/pos/catalog)
// ---------------------------------------------------------------------------

final isCatalogLoadingProvider = StateProvider<bool>((ref) => false);
final catalogErrorProvider = StateProvider<String?>((ref) => null);

class PosProductsNotifier extends Notifier<List<PosProduct>> {
  @override
  List<PosProduct> build() {
    // Memulai pemanggilan katalog secara real-time dari API Kato POS
    Future.microtask(() => fetchCatalog());
    return const [];
  }

  /// Mengambil data produk langsung dari API Kato POS (`/api/v1/pos/catalog` atau `/api/v1/products`)
  Future<void> fetchCatalog({
    int? categoryId,
    String? search,
    int? outletId,
  }) async {
    ref.read(isCatalogLoadingProvider.notifier).state = true;
    ref.read(catalogErrorProvider.notifier).state = null;

    final targetOutletId = outletId ??
        ref.read(selectedOutletProvider)?.id ??
        ref.read(currentUserProvider)?.outletId ??
        1;

    final repo = ref.read(posRepositoryProvider);
    final (products, failure) = await repo.getCatalog(
      categoryId: categoryId,
      search: search,
      outletId: targetOutletId,
    );

    ref.read(isCatalogLoadingProvider.notifier).state = false;

    if (failure != null) {
      ref.read(catalogErrorProvider.notifier).state = failure.message;
      return;
    }

    if (products != null) {
      state = products;
    }
  }

  void addProduct({
    required String sku,
    required String name,
    required int basePrice,
    required int categoryId,
    required int stock,
    required String packagingInfo,
    required String description,
    String? imageUrl,
  }) {
    final nextId = state.isEmpty
        ? 101
        : state.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

    final newProduct = PosProduct(
      id: nextId,
      sku: sku.toUpperCase(),
      name: name,
      basePrice: basePrice,
      categoryId: categoryId,
      categoryName: packagingInfo.isNotEmpty ? packagingInfo : 'Umum',
      stock: stock,
      packagingInfo: packagingInfo.isEmpty
          ? '$name | Kemasan Standar'
          : packagingInfo,
      description: description.isEmpty
          ? 'Produk ritel tersedia pada etalase kasir.'
          : description,
      imageUrl: imageUrl ?? '',
    );

    state = [newProduct, ...state];
  }

  void updateStock(int productId, int delta) {
    state = [
      for (final p in state)
        if (p.id == productId)
          p.copyWith(stock: (p.stock + delta).clamp(0, 9999))
        else
          p,
    ];
  }

  void setStock(int productId, int newStock) {
    state = [
      for (final p in state)
        if (p.id == productId)
          p.copyWith(stock: newStock.clamp(0, 9999))
        else
          p,
    ];
  }

  void deductStock(Map<int, int> qtyByProductId) {
    state = [
      for (final p in state)
        if (qtyByProductId.containsKey(p.id))
          p.copyWith(stock: (p.stock - qtyByProductId[p.id]!).clamp(0, 9999))
        else
          p,
    ];
  }
}

final posProductsProvider =
    NotifierProvider<PosProductsNotifier, List<PosProduct>>(
  PosProductsNotifier.new,
);

/// Daftar kategori aktif dari API Kato POS (`/api/v1/categories`)
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final repo = ref.read(posRepositoryProvider);
  final (cats, _) = await repo.getCategories();
  const defaultAll = ProductCategory(id: 0, name: 'Semua');
  if (cats != null && cats.isNotEmpty) {
    return [defaultAll, ...cats];
  }
  return const [defaultAll];
});

final selectedCategoryIdProvider = StateProvider<int>((ref) => 0);
final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<List<PosProduct>>((ref) {
  final products = ref.watch(posProductsProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final query = ref.watch(catalogSearchQueryProvider).trim().toLowerCase();

  return products.where((product) {
    final matchesCategory = categoryId == 0 || product.categoryId == categoryId;
    if (!matchesCategory) return false;
    if (query.isEmpty) return true;
    return product.name.toLowerCase().contains(query) ||
        product.sku.toLowerCase().contains(query) ||
        product.categoryName.toLowerCase().contains(query);
  }).toList();
});

// ---------------------------------------------------------------------------
// Cart (Keranjang Kasir) State - Dimulai dalam keadaan kosong tanpa dummy
// ---------------------------------------------------------------------------

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Adds or updates a product in the cart, respecting available stock.
  /// Returns false if requested quantity exceeds stock.
  bool addOrUpdate(PosProduct product, {int delta = 1}) {
    if (product.isOutOfStock && delta > 0) return false;

    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      if (delta <= 0) return false;
      final clampedQty = delta.clamp(1, product.stock);
      state = [...state, CartItem(product: product, qty: clampedQty)];
      return true;
    }

    final current = state[index];
    final nextQty = current.qty + delta;
    if (nextQty <= 0) {
      removeItem(product.id);
      return true;
    }
    if (nextQty > product.stock) {
      return false;
    }

    final updated = [...state];
    updated[index] = current.copyWith(product: product, qty: nextQty);
    state = updated;
    return true;
  }

  /// Sets exact quantity for a product (used from the Detail Produk modal).
  void setExactQuantity(PosProduct product, int qty) {
    if (qty <= 0 || product.isOutOfStock) {
      removeItem(product.id);
      return;
    }
    final safeQty = qty.clamp(1, product.stock);
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, qty: safeQty)];
    } else {
      final updated = [...state];
      updated[index] = state[index].copyWith(product: product, qty: safeQty);
      state = updated;
    }
  }

  void removeItem(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = const [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final selectedPaymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.cash);

final cartTotalAmountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.subtotal);
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.qty);
});

// ---------------------------------------------------------------------------
// Sales & Transactions State
// ---------------------------------------------------------------------------

class SalesNotifier extends Notifier<List<SaleRecord>> {
  @override
  List<SaleRecord> build() {
    Future.microtask(() => fetchSalesFromApi());
    return PosDummyData.initialSales;
  }

  /// Mengambil data riwayat transaksi penjualan langsung dari API backend (`/api/v1/sales`).
  Future<void> fetchSalesFromApi({
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      final repo = ref.read(posRepositoryProvider);
      final (sales, failure) = await repo.getSales(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      if (sales != null && sales.isNotEmpty) {
        state = sales;
      }
    } catch (_) {}
  }

  SaleRecord createSale({
    required List<CartItem> cartItems,
    required PaymentMethod paymentMethod,
    required TransactionStatus status,
    required String cashierName,
    int? amountPaid,
  }) {
    final total = cartItems.fold<int>(0, (sum, i) => sum + i.subtotal);
    final paid = status == TransactionStatus.cancelled
        ? 0
        : (amountPaid ?? total);
    final change = (paid - total).clamp(0, 99999999);

    final nextId = state.isEmpty
        ? 5001
        : state.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    final seq = (nextId - 5000).toString().padLeft(3, '0');

    final record = SaleRecord(
      id: nextId,
      invoiceNumber: 'INV-20261013-$seq',
      terminalCode: PosDummyData.terminalInfo.machineCode,
      cashierName: cashierName,
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      status: status,
      totalAmount: total,
      amountPaid: paid,
      changeAmount: change,
      items: [
        for (final item in cartItems)
          SaleItemRecord(
            productId: item.product.id,
            sku: item.product.sku,
            productName: item.product.name,
            unitPrice: item.product.basePrice,
            qty: item.qty,
          ),
      ],
    );

    state = [record, ...state];

    if (status == TransactionStatus.completed) {
      final deductMap = <int, int>{
        for (final item in cartItems) item.product.id: item.qty,
      };
      ref.read(posProductsProvider.notifier).deductStock(deductMap);

      // Check if any product dropped to low/out of stock and notify
      final updatedProducts = ref.read(posProductsProvider);
      for (final item in cartItems) {
        final current = updatedProducts.firstWhere(
          (p) => p.id == item.product.id,
          orElse: () => item.product,
        );
        if (current.isOutOfStock) {
          ref.read(notificationsProvider.notifier).addNotification(
                title: 'Stok Habis: ${current.name}',
                message:
                    'SKU ${current.sku} baru saja habis terjual pada transaksi ${record.invoiceNumber}.',
                severity: NotificationSeverity.error,
              );
        } else if (current.isLowStock) {
          ref.read(notificationsProvider.notifier).addNotification(
                title: 'Stok Menipis: ${current.name}',
                message:
                    'Sisa stok SKU ${current.sku} tinggal ${current.stock} unit.',
                severity: NotificationSeverity.warning,
              );
        }
      }
    }

    return record;
  }

  /// Menambahkan transaksi penjualan nyata dari respon API backend (`/api/v1/pos/checkout`).
  void addSale(SaleRecord record) {
    // Jika record dengan ID / invoice sama sudah tercatat (misal dari PENDING ke COMPLETED), perbarui datanya.
    final existingIndex = state.indexWhere(
      (s) => s.id == record.id || s.invoiceNumber == record.invoiceNumber,
    );
    if (existingIndex != -1) {
      final updated = [...state];
      updated[existingIndex] = record;
      state = updated;
      if (record.status == TransactionStatus.completed) {
        final deductMap = <int, int>{
          for (final item in record.items) item.productId: item.qty,
        };
        ref.read(posProductsProvider.notifier).deductStock(deductMap);
      }
      return;
    }

    state = [record, ...state];

    if (record.status == TransactionStatus.completed) {
      final deductMap = <int, int>{
        for (final item in record.items) item.productId: item.qty,
      };
      ref.read(posProductsProvider.notifier).deductStock(deductMap);
    }
  }

  /// Manual webhook status sync for pending QRIS transactions (FAQ Q9).
  void verifyPendingSale(int saleId) {
    final targetIndex = state.indexWhere((s) => s.id == saleId);
    if (targetIndex == -1) return;

    final sale = state[targetIndex];
    if (sale.status != TransactionStatus.pending) return;

    final updated = [...state];
    updated[targetIndex] = sale.copyWith(status: TransactionStatus.completed);
    state = updated;

    final deductMap = <int, int>{
      for (final item in sale.items) item.productId: item.qty,
    };
    ref.read(posProductsProvider.notifier).deductStock(deductMap);

    ref.read(notificationsProvider.notifier).addNotification(
          title: 'Transaksi QRIS Terverifikasi (${sale.invoiceNumber})',
          message:
              'Sinkronisasi pembayaran berhasil. Status transaksi telah diperbarui menjadi Selesai.',
          severity: NotificationSeverity.success,
        );
  }

  /// Membatalkan transaksi penjualan pending ke backend (`/api/v1/sales/{sale_id}/cancel`)
  /// dan memperbarui status pada riwayat transaksi di state secara reaktif.
  Future<(bool, String?)> cancelSale(int saleId, {String? reason}) async {
    try {
      final repo = ref.read(posRepositoryProvider);
      final (success, message, failure) = await repo.cancelSale(
        saleId: saleId,
        reason: reason,
      );

      if (success) {
        // Perbarui status transaksi lokal di state riwayat transaksi
        state = [
          for (final sale in state)
            if (sale.id == saleId)
              sale.copyWith(status: TransactionStatus.cancelled)
            else
              sale,
        ];

        // Refresh katalog produk agar pengembalian stok oleh server langsung terlihat di POS
        final selectedOutlet = ref.read(selectedOutletProvider);
        final currentUser = ref.read(currentUserProvider);
        final outletId = selectedOutlet?.id ?? currentUser?.outletId ?? 1;
        ref.read(posProductsProvider.notifier).fetchCatalog(outletId: outletId);

        // Ambil ulang data sales dari API secara background untuk sinkronisasi penuh
        fetchSalesFromApi();

        return (
          true,
          message ?? 'Transaksi berhasil dibatalkan dan stok dikembalikan'
        );
      }

      return (false, failure?.message ?? 'Gagal membatalkan transaksi');
    } catch (e) {
      return (false, e.toString());
    }
  }

  /// Memperbarui status transaksi yang ada di history secara lokal
  void updateSaleStatus(int saleId, TransactionStatus newStatus) {
    state = [
      for (final sale in state)
        if (sale.id == saleId)
          sale.copyWith(status: newStatus)
        else
          sale,
    ];
  }
}

final salesProvider = NotifierProvider<SalesNotifier, List<SaleRecord>>(
  SalesNotifier.new,
);

final salesStatusFilterProvider = StateProvider<TransactionStatus?>((ref) => null);

final filteredSalesProvider = Provider<List<SaleRecord>>((ref) {
  final sales = ref.watch(salesProvider);
  final statusFilter = ref.watch(salesStatusFilterProvider);
  if (statusFilter == null) return sales;
  return sales.where((s) => s.status == statusFilter).toList();
});

// ---------------------------------------------------------------------------
// POS Connectivity State (`/api/v1/pos/ping`)
// ---------------------------------------------------------------------------

class PosConnectivityNotifier extends Notifier<PosConnectivity> {
  @override
  PosConnectivity build() {
    Future.microtask(() => checkConnectivity());
    return PosConnectivity.initial();
  }

  /// Mengecek status koneksi online POS ke server (`/api/v1/pos/ping`)
  Future<void> checkConnectivity() async {
    try {
      final repo = ref.read(posRepositoryProvider);
      final (connectivity, failure) = await repo.pingPos();
      if (connectivity != null) {
        state = connectivity;
      } else if (failure != null) {
        state = state.copyWith(
          isOnline: false,
          status: 'OFFLINE',
          friendlyMessage: failure.message,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isOnline: false,
        status: 'OFFLINE',
        friendlyMessage: 'Perangkat kasir terputus / offline',
      );
    }
  }
}

final posConnectivityProvider =
    NotifierProvider<PosConnectivityNotifier, PosConnectivity>(
  PosConnectivityNotifier.new,
);

// ---------------------------------------------------------------------------
// System Notifications State
// ---------------------------------------------------------------------------

class NotificationsNotifier extends Notifier<List<SystemNotification>> {
  @override
  List<SystemNotification> build() => PosDummyData.initialNotifications;

  void markAsRead(int id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationSeverity severity,
  }) {
    final nextId = state.isEmpty
        ? 1
        : state.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    final notification = SystemNotification(
      id: nextId,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      severity: severity,
    );
    state = [notification, ...state];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<SystemNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});

// ---------------------------------------------------------------------------
// Staff Users State (Dummy RBAC Management)
// ---------------------------------------------------------------------------

class StaffUsersNotifier extends Notifier<List<UserProfile>> {
  @override
  List<UserProfile> build() => PosDummyData.initialStaffUsers;

  UserProfile createStaff({
    required String username,
    required String email,
    String? fullName,
    String role = 'staff',
  }) {
    final nextId = state.isEmpty
        ? 1
        : state.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1;
    final newUser = UserProfile(
      id: nextId,
      username: username,
      email: email,
      fullName: fullName,
      isActive: true,
      role: role,
    );
    state = [...state, newUser];
    return newUser;
  }
}

final staffUsersProvider =
    NotifierProvider<StaffUsersNotifier, List<UserProfile>>(
  StaffUsersNotifier.new,
);

// ---------------------------------------------------------------------------
// Printer & Hardware Configuration State
// ---------------------------------------------------------------------------

enum PrinterPaperSize {
  mm58('58 mm', 32, 'Kecil / Portable (32 Karakter per baris)'),
  mm80('80 mm', 48, 'Besar / Meja (48 Karakter per baris)');

  final String label;
  final int maxChars;
  final String description;
  const PrinterPaperSize(this.label, this.maxChars, this.description);
}

enum PrinterConnectionType {
  bluetooth('Bluetooth (Nirkabel)', Icons.bluetooth_rounded),
  usb('Kabel USB / OTG', Icons.usb_rounded),
  network('Wi-Fi / LAN (Jaringan)', Icons.wifi_rounded);

  final String label;
  final IconData icon;
  const PrinterConnectionType(this.label, this.icon);
}

class PrinterConfig {
  final PrinterPaperSize paperSize;
  final PrinterConnectionType connectionType;
  final String deviceName;
  final String? macAddress;
  final bool isConnected;
  final bool autoPrintOnCheckout;
  final bool openCashDrawer;
  final bool autoCut;
  final bool isTaxEnabled;
  final bool isServiceChargeEnabled;

  const PrinterConfig({
    this.paperSize = PrinterPaperSize.mm58,
    this.connectionType = PrinterConnectionType.bluetooth,
    this.deviceName = 'Belum Terhubung',
    this.macAddress,
    this.isConnected = false,
    this.autoPrintOnCheckout = true,
    this.openCashDrawer = true,
    this.autoCut = true,
    this.isTaxEnabled = true,
    this.isServiceChargeEnabled = false,
  });

  PrinterConfig copyWith({
    PrinterPaperSize? paperSize,
    PrinterConnectionType? connectionType,
    String? deviceName,
    String? macAddress,
    bool? isConnected,
    bool? autoPrintOnCheckout,
    bool? openCashDrawer,
    bool? autoCut,
    bool? isTaxEnabled,
    bool? isServiceChargeEnabled,
  }) {
    return PrinterConfig(
      paperSize: paperSize ?? this.paperSize,
      connectionType: connectionType ?? this.connectionType,
      deviceName: deviceName ?? this.deviceName,
      macAddress: macAddress ?? this.macAddress,
      isConnected: isConnected ?? this.isConnected,
      autoPrintOnCheckout: autoPrintOnCheckout ?? this.autoPrintOnCheckout,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      autoCut: autoCut ?? this.autoCut,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      isServiceChargeEnabled:
          isServiceChargeEnabled ?? this.isServiceChargeEnabled,
    );
  }
}

class PrinterConfigNotifier extends Notifier<PrinterConfig> {
  @override
  PrinterConfig build() => const PrinterConfig();

  void updatePaperSize(PrinterPaperSize size) {
    state = state.copyWith(paperSize: size);
  }

  void updateConnectionType(PrinterConnectionType type) {
    state = state.copyWith(connectionType: type);
  }

  void setDeviceName(String name) {
    state = state.copyWith(deviceName: name);
  }

  void setConnectedDevice({
    required String name,
    required String macAddress,
    required bool connected,
  }) {
    state = state.copyWith(
      deviceName: name,
      macAddress: macAddress,
      isConnected: connected,
    );
  }

  void setConnectionStatus(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  void toggleAutoPrint(bool value) {
    state = state.copyWith(autoPrintOnCheckout: value);
  }

  void toggleCashDrawer(bool value) {
    state = state.copyWith(openCashDrawer: value);
  }

  void toggleAutoCut(bool value) {
    state = state.copyWith(autoCut: value);
  }

  void toggleTax(bool value) {
    state = state.copyWith(isTaxEnabled: value);
  }

  void toggleServiceCharge(bool value) {
    state = state.copyWith(isServiceChargeEnabled: value);
  }
}

final printerConfigProvider =
    NotifierProvider<PrinterConfigNotifier, PrinterConfig>(
  PrinterConfigNotifier.new,
);

