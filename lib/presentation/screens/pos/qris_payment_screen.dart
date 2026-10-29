import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/services/thermal_printer_service.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/data/repositories/pos_repository_impl.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/payment_background_scaffold.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/qris_code_display.dart';

/// Halaman Pembayaran QRIS Dinamis Kato POS sesuai Gambar 2.
/// Menampilkan template background ungu dengan shape lengkung login/lupa password,
/// kartu putih elegan di tengah, kode QR dengan bingkai scanner sudut 4 sisi,
/// nominal Total Tagihan, status "Menunggu Konfirmasi Pembayaran",
/// serta tombol "Batalkan Pembayaran".
class QrisPaymentScreen extends ConsumerStatefulWidget {
  const QrisPaymentScreen({super.key});

  @override
  ConsumerState<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends ConsumerState<QrisPaymentScreen> {
  QrisPaymentInfo? _qrisInfo;
  CheckoutResult? _qrisCheckoutResult;
  bool _isLoadingQris = false;
  String? _qrisErrorMessage;
  Timer? _qrisPollTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateQris();
    });
  }

  @override
  void dispose() {
    _qrisPollTimer?.cancel();
    super.dispose();
  }

  void _onCancel() {
    _qrisPollTimer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Memulai alur inisiasi QRIS dinamis via API
  Future<void> _initiateQris() async {
    final cartItems = ref.read(cartProvider);
    final total = ref.read(cartTotalAmountProvider);
    if (cartItems.isEmpty) return;

    final user = ref.read(currentUserProvider);
    final outletId = user?.outletId ??
        (cartItems.isNotEmpty ? cartItems.first.product.outletId : 1);
    final repo = ref.read(posRepositoryProvider);

    setState(() {
      _isLoadingQris = true;
      _qrisErrorMessage = null;
    });

    // 1. Eksekusi Checkout Kasir via API /api/v1/pos/checkout untuk QRIS
    final (checkoutResult, checkoutFailure) = await repo.checkout(
      outletId: outletId,
      paymentMethod: 'QRIS',
      cashReceived: total,
      items: cartItems,
      receiptFormat: 'A',
    );

    if (!mounted) return;

    if (checkoutFailure != null || checkoutResult == null) {
      setState(() {
        _isLoadingQris = false;
        _qrisErrorMessage = checkoutFailure?.message ??
            'Gagal memulai transaksi QRIS di server KatoPOS.';
      });
      return;
    }

    _qrisCheckoutResult = checkoutResult;

    // 2. Inisiasi QRIS dinamis via API /api/v1/sales/{sale_id}/payments/qris
    final (qrisInfo, qrisFailure) = await repo.initiateQris(
      saleId: checkoutResult.saleId,
    );

    if (!mounted) return;

    if (qrisFailure != null || qrisInfo == null) {
      setState(() {
        _isLoadingQris = false;
        _qrisErrorMessage = qrisFailure?.message ??
            'Gagal menghasilkan barcode QRIS dinamis dari payment gateway.';
      });
      return;
    }

    setState(() {
      _qrisInfo = qrisInfo;
      _isLoadingQris = false;
    });

    // 3. Mulai polling status otomatis tiap 4 detik
    _startQrisPolling(qrisInfo.paymentId);
  }

  void _startQrisPolling(int paymentId) {
    _qrisPollTimer?.cancel();
    _qrisPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final repo = ref.read(posRepositoryProvider);
      final (statusInfo, _) =
          await repo.checkPaymentStatus(paymentId: paymentId);
      if (!mounted) return;

      if (statusInfo != null) {
        if (statusInfo.isPaid) {
          _qrisPollTimer?.cancel();
          _onPaymentSuccess(
            saleRecord: _qrisCheckoutResult!
                .toSaleRecord(method: PaymentMethod.qris),
          );
        } else if (statusInfo.isExpired) {
          _qrisPollTimer?.cancel();
          setState(() {
            _qrisErrorMessage =
                'QRIS telah kedaluwarsa. Silakan muat ulang transaksi.';
          });
        }
      }
    });
  }

  /// Penanganan saat pembayaran QRIS berhasil terkonfirmasi
  Future<void> _onPaymentSuccess({required SaleRecord saleRecord}) async {
    _qrisPollTimer?.cancel();
    ref.read(salesProvider.notifier).addSale(saleRecord);
    ref.read(cartProvider.notifier).clear();

    // Auto-Print Struk jika printer thermal Bluetooth aktif
    final printerConfig = ref.read(printerConfigProvider);
    if (printerConfig.autoPrintOnCheckout && printerConfig.isConnected) {
      ref.read(thermalPrinterServiceProvider).printSaleReceipt(
            config: printerConfig,
            sale: saleRecord,
            storeName: saleRecord.terminalCode.isNotEmpty
                ? saleRecord.terminalCode
                : 'Kato POS Outlet',
            storeAddress: 'Jl. Jenderal Sudirman No. 1, Jakarta Pusat',
            storePhone: '+62 812-3456-7890',
            footerMessage: 'Terima kasih atas kunjungan Anda!',
          );
    }

    if (!mounted) return;

    // Navigasi ke Halaman Pembayaran Berhasil & Format Struk (Gambar 1)
    context.go(AppRoutes.paymentSuccess, extra: saleRecord);
  }

  /// Opsi simulasi pelunasan instan untuk pengujian lokal / sandbox
  Future<void> _simulateOrVerify() async {
    if (_qrisInfo == null) return;

    setState(() => _isProcessing = true);
    final repo = ref.read(posRepositoryProvider);

    // Coba trigger simulate-pay endpoint
    await repo.simulateQrisPayment(paymentId: _qrisInfo!.paymentId);
    final (isPaid, _, _) =
        await repo.verifyPayment(paymentId: _qrisInfo!.paymentId);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (isPaid && _qrisCheckoutResult != null) {
      _onPaymentSuccess(
        saleRecord:
            _qrisCheckoutResult!.toSaleRecord(method: PaymentMethod.qris),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sedang memeriksa status QRIS... Belum ada pembayaran masuk.',
            style: TextStyle(fontFamily: 'Open Sans', color: Colors.white),
          ),
          backgroundColor: Color(0xFF5247A1),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTagihan = ref.watch(cartTotalAmountProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PaymentBackgroundScaffold(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: isMobile ? 420 : 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 36,
          vertical: isMobile ? 28 : 36,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon Logo Kato POS
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/Logo/logo_kato_pos.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5247A1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Teks Nama Sistem
            const Text(
              'Kato POS System',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF4A409A),
              ),
            ),
            const SizedBox(height: 22),

            // 3. Tampilan QR Code dengan Bingkai Scanner Membulat
            QrisCodeDisplay(
              qrData: _qrisInfo?.qrPayload,
              isLoading: _isLoadingQris,
              size: isMobile ? 180 : 196,
              onTap: _simulateOrVerify,
            ),
            const SizedBox(height: 22),

            // 4. Label Total Tagihan
            const Text(
              'Total Tagihan',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // 5. Nominal Tagihan Besar
            Text(
              AppFormatters.formatRupiah(totalTagihan),
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w800,
                fontSize: 30,
                color: Color(0xFF4A409A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // 6. Label Status Menunggu Konfirmasi Pembayaran
            InkWell(
              onTap: _simulateOrVerify,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _qrisErrorMessage ?? 'Menunggu Konfirmasi Pembayaran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 12.5 : 13.5,
                        color: _qrisErrorMessage != null
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. Tombol Batalkan Pembayaran (Filled Style sesuai Gambar 2)
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A409A),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: const Text(
                  'Batalkan Pembayaran',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
