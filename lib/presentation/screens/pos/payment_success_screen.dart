import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/payment_background_scaffold.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/thermal_receipt_preview_dialog.dart';

/// Halaman Pembayaran Berhasil & Pemilihan Format Struk Kato POS sesuai Gambar 1.
/// Dilengkapi opsi format struk ("Dengan Total" & "Tanpa Total"), tombol Cetak Struk
/// yang menampilkan pratinjau struk termal 58mm (Gambar 2 & 3), serta tombol Kembali ke Katalog.
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final SaleRecord? saleRecord;

  const PaymentSuccessScreen({
    super.key,
    this.saleRecord,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  // Format A: Dengan Total, Format B: Tanpa Total
  String _selectedReceiptFormat = 'A';

  void _openReceiptPreview(SaleRecord sale) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ThermalReceiptPreviewDialog(
        sale: sale,
        showTotals: _selectedReceiptFormat == 'A',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data sale dari parameter atau fallback ke riwayat transaksi terkini
    final recentSales = ref.watch(salesProvider);
    final sale = widget.saleRecord ??
        (recentSales.isNotEmpty
            ? recentSales.first
            : SaleRecord(
                id: 1,
                invoiceNumber: 'TRX-20261023-012',
                createdAt: DateTime.now(),
                totalAmount: 0,
                cashierName: 'Shinta',
                terminalCode: 'KATO-POS-01',
                paymentMethod: PaymentMethod.cash,
                status: TransactionStatus.completed,
                amountPaid: 0,
                changeAmount: 0,
                items: const [],
              ));

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isCash = sale.paymentMethod == PaymentMethod.cash;

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

            // 2. Nama Sistem
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

            // 3. Ikon Centang Berhasil dengan Lingkaran Bertingkat (Halo Effect)
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF5247A1).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5247A1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 4. Judul Pembayaran Berhasil!
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // 5. No. Transaksi
            Text(
              'No. Transaksi #${sale.invoiceNumber}',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Ringkasan Info Pembayaran (Box Abu-Abu)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryInfoRow(
                    'Metode',
                    isCash ? 'Tunai' : 'QRIS',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryInfoRow(
                    'Total Bayar',
                    AppFormatters.formatRupiah(sale.totalAmount),
                  ),
                  const SizedBox(height: 8),
                  if (isCash)
                    _buildSummaryInfoRow(
                      'Kembalian',
                      AppFormatters.formatRupiah(sale.changeAmount),
                    )
                  else
                    _buildSummaryInfoRow(
                      'Ref',
                      sale.terminalCode.isNotEmpty ? sale.terminalCode : '#####',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 7. Pilih Format Struk
            const Text(
              'Pilih Format Struk',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

            // Radio Button Opsi Format Struk
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFormatRadioOption(
                  label: 'Dengan Total',
                  value: 'A',
                ),
                const SizedBox(width: 16),
                _buildFormatRadioOption(
                  label: 'Tanpa Total',
                  value: 'B',
                ),
              ],
            ),
            const SizedBox(height: 26),

            // 8. Tombol Aksi: Cetak Struk & Kembali ke Katalog
            Row(
              children: [
                // Tombol Cetak Struk (Filled Style)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _openReceiptPreview(sale),
                      icon: const Icon(
                        Icons.print_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cetak Struk',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A409A),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Kembali ke Katalog (Outlined Style)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
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
                          'Kembali ke Katalog',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatRadioOption({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedReceiptFormat == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedReceiptFormat = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5247A1)
                      : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5247A1),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
