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

  void _onCancel() async {
    _qrisPollTimer?.cancel();
    if (_qrisCheckoutResult != null) {
      final saleId = _qrisCheckoutResult!.saleId;
      await ref.read(salesProvider.notifier).cancelSale(
            saleId,
            reason: 'Dibatalkan oleh kasir di layar pembayaran QRIS',
          );
    }
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go(AppRoutes.home);
        } catch (_) {}
      }
    }
  }

  /// Memulai alur inisiasi QRIS dinamis via API
  Future<void> _initiateQris() async {
    final cartItems = ref.read(cartProvider);
    final total = ref.read(cartTotalAmountProvider);
    if (cartItems.isEmpty) return;

    final selectedOutlet = ref.read(selectedOutletProvider);
    final user = ref.read(currentUserProvider);
    final outletId = selectedOutlet?.id ??
        user?.outletId ??
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
    final selectedOutlet = ref.read(selectedOutletProvider);
    ref.read(salesProvider.notifier).addSale(saleRecord);
    ref.read(cartProvider.notifier).clear();

    // Auto-Print Struk jika printer thermal Bluetooth aktif
    final printerConfig = ref.read(printerConfigProvider);
    if (printerConfig.autoPrintOnCheckout && printerConfig.isConnected) {
      ref.read(thermalPrinterServiceProvider).printSaleReceipt(
            config: printerConfig,
            sale: saleRecord,
            storeName: selectedOutlet?.name ??
                (saleRecord.terminalCode.isNotEmpty
                    ? saleRecord.terminalCode
                    : 'Kopi Kato - Cabang Sudirman'),
            storeAddress: selectedOutlet?.address ??
                'Jl. Jenderal Sudirman No. 1, Jakarta Pusat',
            storePhone: selectedOutlet?.phone ?? '+62 812-3456-7890',
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
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isMobile = screenWidth < 600;
    final isLandscapeShort = screenHeight < 520;

    return PaymentBackgroundScaffold(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isLandscapeShort ? 620 : (isMobile ? 420 : 480),
        ),
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
          horizontal: isLandscapeShort ? 24 : (isMobile ? 24 : 36),
          vertical: isLandscapeShort ? 18 : (isMobile ? 28 : 36),
        ),
        child: isLandscapeShort
            ? _buildLandscapeContent(context, totalTagihan)
            : _buildPortraitContent(context, totalTagihan, isMobile),
      ),
    );
  }

  /// Tampilan Responsif Mode Landscape untuk HP (Side-by-Side 2 Kolom)
  Widget _buildLandscapeContent(BuildContext context, int totalTagihan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Scanner QRIS Kompak
        QrisCodeDisplay(
          qrData: _qrisInfo?.qrPayload,
          isLoading: _isLoadingQris,
          size: 150,
          onTap: _simulateOrVerify,
        ),
        const SizedBox(width: 24),

        // Sisi Kanan: Info Pembayaran, Status, dan Tombol Batal
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Ringkas: Logo + Nama Sistem
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/Logo/logo_kato_pos.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5247A1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Kato POS System',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF4A409A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Total Tagihan & Nominal
              const Text(
                'Total Tagihan',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppFormatters.formatRupiah(totalTagihan),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Color(0xFF4A409A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Status / Error Pesan Responsif
              _buildStatusOrErrorWidget(isMobile: true),
              const SizedBox(height: 12),

              // Tombol Batal
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A409A),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'Batalkan Pembayaran',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tampilan Portrait / Tablet Layar Standar (1 Kolom Vertikal)
  Widget _buildPortraitContent(
    BuildContext context,
    int totalTagihan,
    bool isMobile,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Icon Logo Kato POS
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/Logo/logo_kato_pos.png',
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5247A1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Teks Nama Sistem
        Text(
          'Kato POS System',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15 : 16,
            color: const Color(0xFF4A409A),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 22),

        // 3. Tampilan QR Code dengan Bingkai Scanner Membulat
        QrisCodeDisplay(
          qrData: _qrisInfo?.qrPayload,
          isLoading: _isLoadingQris,
          size: isMobile ? 170 : 196,
          onTap: _simulateOrVerify,
        ),
        SizedBox(height: isMobile ? 16 : 22),

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
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w800,
            fontSize: isMobile ? 26 : 30,
            color: const Color(0xFF4A409A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),

        // 6. Label Status / Error Menunggu Konfirmasi Pembayaran
        _buildStatusOrErrorWidget(isMobile: isMobile),
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
    );
  }

  /// Widget Status / Error Responsif (Anti-Overflow dengan wrapping teks rapi)
  Widget _buildStatusOrErrorWidget({required bool isMobile}) {
    final isError = _qrisErrorMessage != null;

    return InkWell(
      onTap: _simulateOrVerify,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: EdgeInsets.symmetric(
          horizontal: isError ? 12 : 8,
          vertical: isError ? 6 : 4,
        ),
        decoration: isError
            ? BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              )
            : null,
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
            ] else if (isError) ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                _qrisErrorMessage ?? 'Menunggu Konfirmasi Pembayaran',
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: isError ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 13,
                  color: isError
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}