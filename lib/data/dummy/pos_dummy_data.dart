import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// Centralized configuration dataset.
/// Seluruh data dummy produk, staf, dan transaksi telah dibersihkan (empty list)
/// karena data katalog diambil secara real-time dari backend API Kato POS.
class PosDummyData {
  PosDummyData._();

  static const UserProfile defaultCashierUser = UserProfile(
    id: 1,
    username: 'kasir@katopos.id',
    email: 'kasir@katopos.id',
    fullName: 'Kasir Kato POS',
    isActive: true,
    role: 'cashier',
  );

  static const List<UserProfile> initialStaffUsers = [];

  static const List<ProductCategory> categories = [
    ProductCategory(id: 0, name: 'Semua'),
  ];

  static String defaultImageForCategory(int categoryId) {
    return '';
  }

  /// Daftar produk awal dikosongkan total; diisi secara langsung dari API `/api/v1/pos/catalog`.
  static const List<PosProduct> initialProducts = [];

  /// Riwayat transaksi awal sesuai referensi desain Kato POS (diperkaya otomatis dari API `/api/v1/sales`).
  static List<SaleRecord> get initialSales => [
        SaleRecord(
          id: 1001,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
            SaleItemRecord(
              productId: 102,
              productName: 'Matcha Latte Art',
              sku: 'P0002',
              qty: 4,
              unitPrice: 40000,
            ),
            SaleItemRecord(
              productId: 103,
              productName: 'Croissant Butter Original',
              sku: 'P0003',
              qty: 3,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1002,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1003,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1004,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1005,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1006,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
        SaleRecord(
          id: 1007,
          invoiceNumber: 'INV-XXXX-XXXX',
          terminalCode: 'Kato POS Sudirman',
          cashierName: 'Sekarisma Putri',
          createdAt: DateTime(2026, 10, 23, 12, 1),
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.completed,
          totalAmount: 320000,
          amountPaid: 320000,
          changeAmount: 0,
          items: const [
            SaleItemRecord(
              productId: 101,
              productName: 'Mille-Feuille / Vanilla Slice',
              sku: 'P0001',
              qty: 2,
              unitPrice: 32000,
            ),
          ],
        ),
      ];

  static List<SystemNotification> get initialNotifications => const [];
  static List<SystemNotification> get systemNotifications => const [];

  static PosTerminalInfo get terminalInfo => PosTerminalInfo(
        id: 1,
        machineCode: 'POS-KTO-001',
        name: 'Kasir Utama — Kato & Co. Sudirman',
        locationName: 'Sudirman, Jakarta',
        status: 'active',
        paymentGateway: 'Midtrans & Xendit QRIS',
        printerStatus: 'Terhubung (Thermal 58mm)',
        lastSync: DateTime.now(),
      );
}
