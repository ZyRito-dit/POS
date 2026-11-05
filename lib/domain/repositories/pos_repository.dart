import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// Kontrak repositori untuk data produk katalog kasir dan kategori.
/// Menerapkan prinsip Clean Architecture murni tanpa ketergantungan library I/O.
abstract interface class PosRepository {
  /// Mengambil daftar produk katalog siap jual dari backend (`/api/v1/pos/catalog` atau `/api/v1/products`).
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  });

  /// Mengambil daftar kategori produk aktif dari backend (`/api/v1/categories`).
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({
    int? outletId,
  });

  /// Memproses checkout kasir secara atomik ke backend (`/api/v1/pos/checkout`).
  /// Mendukung metode pembayaran CASH dan QRIS, serta konfirmasi cash dengan [saleId].
  Future<(CheckoutResult?, AppFailure?)> checkout({
    int? saleId,
    required int outletId,
    required String paymentMethod,
    int? cashReceived,
    required List<CartItem> items,
    String receiptFormat = 'A',
    String? idempotencyKey,
  });

  /// Inisiasi pembayaran QRIS dinamis untuk transaksi penjualan (`/api/v1/sales/{sale_id}/payments/qris`).
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  });

  /// Memeriksa status terkini pembayaran (`/api/v1/payments/{payment_id}`).
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  });

  /// Meminta verifikasi ulang aktif pembayaran ke payment gateway (`/api/v1/payments/{payment_id}/verify`).
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  });

  /// Simulasi pembayaran sukses untuk QRIS (Development / Sandbox) (`/api/v1/payments/{payment_id}/simulate-pay`).
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  });

  /// Mengambil riwayat transaksi penjualan dari backend (`/api/v1/sales`).
  Future<(List<SaleRecord>?, AppFailure?)> getSales({
    int? outletId,
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int perPage = 50,
  });

  /// Memeriksa status konektivitas online perangkat kasir (`/api/v1/pos/ping`).
  Future<(PosConnectivity?, AppFailure?)> pingPos();

  /// Membatalkan transaksi penjualan pending dan mengembalikan stok (`/api/v1/sales/{sale_id}/cancel`).
  Future<(bool, String?, AppFailure?)> cancelSale({
    required int saleId,
    String? reason,
  });
}
