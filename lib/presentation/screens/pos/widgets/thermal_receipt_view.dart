import 'package:flutter/material.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// Widget Struk Kasir Termal 58mm sesuai persis dengan Gambar 2 (Tunai) dan Gambar 3 (QRIS).
/// Menggunakan tipografi monospace, batas lebar 58mm (300-320px), garis putus-putus presisi,
/// serta logo hitam Kato POS di bagian atas.
class ThermalReceiptView extends StatelessWidget {
  final SaleRecord sale;
  final bool showTotals; // true = Dengan Total (Format A), false = Tanpa Total (Format B)

  const ThermalReceiptView({
    super.key,
    required this.sale,
    this.showTotals = true,
  });

  static const String _monospaceFont = 'Courier';
  static const List<String> _monospaceFallback = ['Courier New', 'RobotoMono', 'monospace'];

  @override
  Widget build(BuildContext context) {
    final isCash = sale.paymentMethod == PaymentMethod.cash;

    // Formatting tanggal sesuai format struk gambar: "21/10/2026 12:00:00"
    final dt = sale.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -----------------------------------------------------------------
          // 1. Logo Hitam Kato POS (di-tint murni hitam sesuai gambar)
          // -----------------------------------------------------------------
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              child: Image.asset(
                'assets/Logo/logo_kato_pos.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.storefront_rounded,
                  size: 52,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // -----------------------------------------------------------------
          // 2. Info Toko / Header Struk
          // -----------------------------------------------------------------
          const Text(
            'Kato POS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Apartemen Gardenia Boulevard, 13900\nPasar Minggu, South Jakarta\n(+62) 800-123',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          _buildDashedLine(),
          const SizedBox(height: 12),

          // -----------------------------------------------------------------
          // 3. Metadata Transaksi (Waktu, Kasir, No. Struk)
          // -----------------------------------------------------------------
          _buildMonoRow('Waktu / Tanggal', ':  $dateStr'),
          const SizedBox(height: 4),
          _buildMonoRow('Kasir', ':  ${sale.cashierName.isNotEmpty ? sale.cashierName : "Shinta"}'),
          const SizedBox(height: 4),
          _buildMonoRow('No. Struk', ':  ${sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : "0000000000"}'),
          const SizedBox(height: 12),

          _buildDashedLine(),
          const SizedBox(height: 10),

          // -----------------------------------------------------------------
          // 4. Header Kolom Tabel Produk (No.   Produk     Qty   Price)
          // -----------------------------------------------------------------
          const Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  'No.',
                  style: TextStyle(
                    fontFamily: _monospaceFont,
                    fontFamilyFallback: _monospaceFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Produk',
                  style: TextStyle(
                    fontFamily: _monospaceFont,
                    fontFamilyFallback: _monospaceFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _monospaceFont,
                    fontFamilyFallback: _monospaceFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: _monospaceFont,
                    fontFamilyFallback: _monospaceFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildDashedLine(),
          const SizedBox(height: 12),

          // -----------------------------------------------------------------
          // 5. Daftar Item Belanja
          // -----------------------------------------------------------------
          for (var i = 0; i < sale.items.length; i++) ...[
            _buildItemRow(i + 1, sale.items[i]),
            if (i < sale.items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),

          _buildDashedLine(),
          const SizedBox(height: 12),

          // -----------------------------------------------------------------
          // 6. Ringkasan Total (Subtotal, Pajak, Discount, Total)
          // -----------------------------------------------------------------
          if (showTotals) ...[
            _buildSummaryRow('Subtotal', AppFormatters.formatRupiah(sale.totalAmount)),
            const SizedBox(height: 4),
            _buildSummaryRow('Pajak', 'Rp 0'),
            const SizedBox(height: 4),
            _buildSummaryRow('Total', AppFormatters.formatRupiah(sale.totalAmount), isBold: true),
            const SizedBox(height: 12),
            _buildDashedLine(),
            const SizedBox(height: 12),
          ],

          // -----------------------------------------------------------------
          // 7. Informasi Pembayaran (Tunai / QRIS)
          // -----------------------------------------------------------------
          if (isCash) ...[
            // Gambar 2: Tunai
            _buildSummaryRow('Metode Bayar', 'Tunai'),
            const SizedBox(height: 4),
            _buildSummaryRow('Uang Tunai', AppFormatters.formatRupiah(sale.amountPaid > 0 ? sale.amountPaid : sale.totalAmount)),
            const SizedBox(height: 4),
            _buildSummaryRow('Uang Kembalian', AppFormatters.formatRupiah(sale.changeAmount)),
            const SizedBox(height: 4),
            _buildSummaryRow('Status', 'COMPLETED'),
          ] else ...[
            // Gambar 3: QRIS
            _buildSummaryRow('Metode Bayar', 'QRIS'),
            const SizedBox(height: 4),
            _buildSummaryRow('Ref', sale.terminalCode.isNotEmpty ? sale.terminalCode : '#####'),
            const SizedBox(height: 4),
            _buildSummaryRow('Status', 'COMPLETED'),
          ],
          const SizedBox(height: 12),

          _buildDashedLine(),
          const SizedBox(height: 20),

          // -----------------------------------------------------------------
          // 8. Footer Ucapan Terima Kasih
          // -----------------------------------------------------------------
          const Text(
            'Terima Kasih!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMonoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index, SaleItemRecord item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$index',
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            item.productName,
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
              height: 1.3,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${item.qty}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            AppFormatters.formatRupiah(item.subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _monospaceFont,
              fontFamilyFallback: _monospaceFallback,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: _monospaceFont,
            fontFamilyFallback: _monospaceFallback,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
