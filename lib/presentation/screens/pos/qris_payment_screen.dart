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
  Timer? _countdownTimer;
  Timer? _autoCloseTimer;
  bool _isProcessing = false;
  bool _isExpired = false;
  bool _isCancelled = false;

  // Hitung mundur masa berlaku QRIS (5 menit = 300 detik)
  static const int _initialCountdownSeconds = 300;
  int _remainingSeconds = _initialCountdownSeconds;

  // Hitung mundur penutupan otomatis (10 detik setelah expired/batal)
  int _autoCloseRemainingSeconds = 10;

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
    _countdownTimer?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer({DateTime? expiresAt}) {
    _countdownTimer?.cancel();

    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      _remainingSeconds = diff > 0 ? diff : _initialCountdownSeconds;
    } else {
      _remainingSeconds = _initialCountdownSeconds;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _onExpired();
      }
    });
  }

  void _onExpired() {
    _qrisPollTimer?.cancel();
    _countdownTimer?.cancel();
    if (_isExpired || _isCancelled) return;

    setState(() {
      _isExpired = true;
      _qrisErrorMessage =
          'QRIS telah kedaluwarsa. Silakan buat ulang QR atau ganti ke tunai.';
    });

    _startAutoCloseTimer();
  }

  void _onCancel() async {
    _qrisPollTimer?.cancel();
    _countdownTimer?.cancel();
    if (_isCancelled) return;

    setState(() {
      _isCancelled = true;
      _qrisErrorMessage =
          'Transaksi QRIS dibatalkan. Silakan buat ulang QR atau ganti ke tunai.';
    });

    if (_qrisCheckoutResult != null) {
      final saleId = _qrisCheckoutResult!.saleId;
      ref.read(salesProvider.notifier).cancelSale(
            saleId,
            reason: 'Dibatalkan oleh kasir di layar pembayaran QRIS',
          );
    }

    _startAutoCloseTimer();
  }

  /// Timer tutup otomatis layar (misal kembali ke katalog setelah 10 detik kedaluwarsa/dibatalkan)
  void _startAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseRemainingSeconds = 10;
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoCloseRemainingSeconds > 1) {
        setState(() {
          _autoCloseRemainingSeconds--;
        });
      } else {
        timer.cancel();
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    _qrisPollTimer?.cancel();
    _countdownTimer?.cancel();
    _autoCloseTimer?.cancel();
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

  /// Aksi kasir: Buat ulang kode QRIS
  void _onRetryQris() {
    _autoCloseTimer?.cancel();
    setState(() {
      _isExpired = false;
      _isCancelled = false;
      _qrisErrorMessage = null;
    });
    _initiateQris();
  }

  /// Aksi kasir: Beralih ke metode pembayaran Tunai (Cash)
  void _onSwitchToCash() {
    _autoCloseTimer?.cancel();
    _qrisPollTimer?.cancel();
    _countdownTimer?.cancel();
    ref.read(selectedPaymentMethodProvider.notifier).state = PaymentMethod.cash;
    if (mounted) {
      context.pushReplacement(
        AppRoutes.paymentCash,
        extra: _qrisCheckoutResult,
      );
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
      _isExpired = false;
      _isCancelled = false;
    });

    // 3. Mulai hitung mundur masa berlaku (mengikuti expires_at dari backend jika ada, fallback 5 menit) & polling status otomatis
    _startCountdownTimer(expiresAt: qrisInfo.expiresAt);
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
          _countdownTimer?.cancel();
          _autoCloseTimer?.cancel();
          _onPaymentSuccess(
            saleRecord: _qrisCheckoutResult!
                .toSaleRecord(method: PaymentMethod.qris),
          );
        } else if (statusInfo.isExpired) {
          _onExpired();
        }
      }
    });
  }

  /// Penanganan saat pembayaran QRIS berhasil terkonfirmasi
  Future<void> _onPaymentSuccess({required SaleRecord saleRecord}) async {
    _qrisPollTimer?.cancel();
    final selectedOutlet = ref.read(selectedOutletProvider);

    // Pastikan status saleRecord adalah completed agar stok di-deduct
    final completedRecord = saleRecord.copyWith(
      status: TransactionStatus.completed,
    );
    ref.read(salesProvider.notifier).addSale(completedRecord);
    ref.read(cartProvider.notifier).clear();

    // Re-fetch katalog dari server agar jumlah stok terbaru langsung tersinkronisasi
    ref.read(posProductsProvider.notifier).fetchCatalog(
      outletId: selectedOutlet?.id,
    );

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

  /// Format sisa waktu menit:detik (contoh: 04:59)
  String _formatRemainingTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Tampilan Responsif Mode Landscape untuk HP (Side-by-Side 2 Kolom)
  Widget _buildLandscapeContent(BuildContext context, int totalTagihan) {
    final isInactive = _isExpired || _isCancelled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sisi Kiri: Scanner QRIS Kompak
        QrisCodeDisplay(
          qrData: _qrisInfo?.qrPayload,
          isLoading: _isLoadingQris,
          isExpired: _isExpired,
          isCancelled: _isCancelled,
          size: 150,
          onTap: _simulateOrVerify,
        ),
        const SizedBox(width: 24),

        // Sisi Kanan: Info Pembayaran, Status, dan Tombol Aksi
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

              // Status / Error Pesan Responsif + Timer Masa Berlaku
              _buildStatusOrErrorWidget(isMobile: true),
              const SizedBox(height: 12),

              // Tombol Aksi
              if (isInactive)
                _buildInactiveActionButtons(isMobile: true)
              else
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
    final isInactive = _isExpired || _isCancelled;

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

        // 3. Tampilan QR Code dengan Bingkai Scanner Membulat & Overlay Kadaluarsa/Dibatalkan
        QrisCodeDisplay(
          qrData: _qrisInfo?.qrPayload,
          isLoading: _isLoadingQris,
          isExpired: _isExpired,
          isCancelled: _isCancelled,
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

        // 6. Label Status / Error Menunggu Konfirmasi Pembayaran + Timer
        _buildStatusOrErrorWidget(isMobile: isMobile),
        const SizedBox(height: 24),

        // 7. Tombol Aksi: Batalkan Pembayaran (jika aktif) atau Opsi Buat Ulang / Ganti Tunai (jika kadaluarsa/batal)
        if (isInactive)
          _buildInactiveActionButtons(isMobile: isMobile)
        else
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

  /// Widget Tombol saat QRIS Kadaluarsa atau Dibatalkan
  Widget _buildInactiveActionButtons({required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            // Tombol Buat Ulang QR
            ElevatedButton.icon(
              onPressed: _onRetryQris,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Buat Ulang QR',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A409A),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),

            // Tombol Ganti ke Tunai
            OutlinedButton.icon(
              onPressed: _onSwitchToCash,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text(
                'Ganti ke Tunai',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5247A1), width: 1.5),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5247A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hitung mundur tutup otomatis layar
        InkWell(
          onTap: _navigateBack,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Otomatis kembali dalam $_autoCloseRemainingSeconds detik (Ketuk untuk tutup sekarang)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: isMobile ? 11 : 12,
                color: const Color(0xFF94A3B8),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget Status / Error Responsif (Anti-Overflow dengan wrapping teks rapi)
  Widget _buildStatusOrErrorWidget({required bool isMobile}) {
    final isInactive = _isExpired || _isCancelled;
    final isError = _qrisErrorMessage != null;

    return InkWell(
      onTap: isInactive ? null : _simulateOrVerify,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: EdgeInsets.symmetric(
          horizontal: (isError || isInactive) ? 12 : 8,
          vertical: (isError || isInactive) ? 6 : 4,
        ),
        decoration: (isError || isInactive)
            ? BoxDecoration(
                color: _isExpired
                    ? const Color(0xFFFEF2F2)
                    : (_isCancelled
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFFFEF2F2)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isExpired
                      ? const Color(0xFFFECACA)
                      : (_isCancelled
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFECACA)),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                ] else if (isInactive) ...[
                  Icon(
                    _isExpired
                        ? Icons.timer_off_outlined
                        : Icons.cancel_outlined,
                    size: 16,
                    color: _isExpired
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
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
                    _isExpired
                        ? 'QRIS Kedaluwarsa'
                        : (_isCancelled
                            ? 'Pembayaran Dibatalkan'
                            : (_qrisErrorMessage ??
                                'Menunggu Konfirmasi Pembayaran')),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight:
                          isInactive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isMobile ? 12 : 13,
                      color: _isExpired
                          ? const Color(0xFFDC2626)
                          : (_isCancelled
                              ? const Color(0xFF475569)
                              : (isError
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B))),
                    ),
                  ),
                ),
              ],
            ),
            // Jika QRIS masih aktif, tampilkan sisa waktu countdown 5 menit
            if (!isInactive && _qrisInfo != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: _remainingSeconds <= 60
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Masa berlaku: ${_formatRemainingTime(_remainingSeconds)}',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: _remainingSeconds <= 60
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}