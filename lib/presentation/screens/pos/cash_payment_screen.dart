import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Halaman Pembayaran Tunai (Cash) Kato POS sesuai Gambar 1.
/// Menampilkan template background ungu dengan shape lengkung login/lupa password,
/// kartu putih elegan di tengah, input nominal uang diterima dengan badge 'Rp',
/// preview otomatis uang kembalian, tombol Batalkan Pembayaran & Konfirmasi Pembayaran.
class CashPaymentScreen extends ConsumerStatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  ConsumerState<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends ConsumerState<CashPaymentScreen> {
  final TextEditingController _cashController = TextEditingController();
  final FocusNode _cashFocusNode = FocusNode();
  bool _isCashFocused = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashFocusNode.addListener(_onCashFocusChange);
  }

  void _onCashFocusChange() {
    if (mounted) {
      setState(() {
        _isCashFocused = _cashFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _cashFocusNode.removeListener(_onCashFocusChange);
    _cashFocusNode.dispose();
    _cashController.dispose();
    super.dispose();
  }

  int get _parsedCashReceived {
    final clean = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  void _onCancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmCashPayment(int totalTagihan) async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja kosong.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cashReceived = _parsedCashReceived;
    if (cashReceived < totalTagihan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal uang diterima (${AppFormatters.formatRupiah(cashReceived)}) masih kurang dari total tagihan (${AppFormatters.formatRupiah(totalTagihan)}).',
            style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final selectedOutlet = ref.read(selectedOutletProvider);
    final user = ref.read(currentUserProvider);
    final outletId = selectedOutlet?.id ??
        user?.outletId ??
        (cartItems.isNotEmpty ? cartItems.first.product.outletId : 1);
    final repo = ref.read(posRepositoryProvider);

    // 1. Eksekusi checkout transaksi Tunai via API /api/v1/pos/checkout
    final (result, failure) = await repo.checkout(
      outletId: outletId,
      paymentMethod: 'CASH',
      cashReceived: cashReceived,
      items: cartItems,
      receiptFormat: 'A',
    );

    if (!mounted) return;

    if (failure != null || result == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memproses transaksi: ${failure?.message ?? "Terjadi kesalahan di server."}',
            style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Transaksi Berhasil: Buat SaleRecord & simpan ke riwayat transaksi
    final saleRecord = result.toSaleRecord(method: PaymentMethod.cash);
    ref.read(salesProvider.notifier).addSale(saleRecord);
    ref.read(cartProvider.notifier).clear();

    // 3. Auto-Print Struk jika printer thermal Bluetooth aktif
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

    setState(() => _isProcessing = false);

    // 4. Navigasi ke Halaman Pembayaran Berhasil & Format Struk (Gambar 1)
    if (mounted) {
      context.go(AppRoutes.paymentSuccess, extra: saleRecord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTagihan = ref.watch(cartTotalAmountProvider);
    final cashReceived = _parsedCashReceived;
    final int change = cashReceived >= totalTagihan ? (cashReceived - totalTagihan) : 0;
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
            const SizedBox(height: 20),

            // 3. Label Total Tagihan
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

            // 4. Nominal Tagihan Besar
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
            const SizedBox(height: 24),

            // 5. Input: Nominal Uang Diterima
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nominal Uang Diterima',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12.5 : 13.5,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isCashFocused
                      ? const Color(0xFF5247A1)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: _isCashFocused
                    ? const [
                        BoxShadow(
                          color: Color(0x145247A1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCashFocused
                          ? const Color(0xFFF1F0FA)
                          : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(9),
                        bottomLeft: Radius.circular(9),
                      ),
                      border: Border(
                        right: BorderSide(
                          color: _isCashFocused
                              ? const Color(0xFF5247A1)
                              : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Rp',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _isCashFocused
                            ? const Color(0xFF5247A1)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cashController,
                      focusNode: _cashFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nominal',
                        hintStyle: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Display: Nominal Uang Kembalian
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nominal Uang Kembalian',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12.5 : 13.5,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                ),
              ),
              child: Text(
                cashReceived > 0 && change > 0
                    ? AppFormatters.formatRupiah(change)
                    : 'Rp 0',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A409A),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 7. Tombol Aksi (Batalkan Pembayaran & Konfirmasi Pembayaran)
            Row(
              children: [
                // Tombol Batalkan Pembayaran (Outlined Style)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF5247A1),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5247A1),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Batalkan Pembayaran',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF5247A1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Konfirmasi Pembayaran (Filled Style)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _confirmCashPayment(totalTagihan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A409A),
                        disabledBackgroundColor:
                            const Color(0xFF4A409A).withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Konfirmasi Pembayaran',
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
