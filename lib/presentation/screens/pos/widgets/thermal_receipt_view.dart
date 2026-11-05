import 'package:flutter/material.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// Widget Struk Kasir Termal 58mm sesuai persis dengan referensi desain struk Kato POS.
/// Menggunakan:
/// - Tipografi font 'Roboto Mono' (assets/font/Roboto_Mono)
/// - Logo hitam 'assets/Logo/Logo Struk.png' di bagian atas
/// - Header info toko (Kato POS, alamat, telepon)
/// - Metadata transaksi (Waktu / Tanggal, Kasir, No. Struk)
/// - Tabel daftar item (No., Produk, Qty, Price)
/// - Ringkasan subtotal, pajak, discount, total di sebelah kanan
/// - Rincian pembayaran (Metode Bayar, Uang Tunai, Uang Kembalian, Status COMPLETED)
/// - Footer "Terima Kasih!"
/// - Aksen gerigi potong kertas thermal di sisi atas dan bawah
class ThermalReceiptView extends StatelessWidget {
  final SaleRecord sale;
  final bool showTotals; // true = Dengan Total (Format A), false = Tanpa Total (Format B)

  const ThermalReceiptView({
    super.key,
    required this.sale,
    this.showTotals = true,
  });

  static const String _receiptFont = 'Roboto Mono';
  static const List<String> _receiptFontFallback = [
    'RobotoMono',
    'Courier New',
    'monospace',
  ];

  @override
  Widget build(BuildContext context) {
    final isCash = sale.paymentMethod == PaymentMethod.cash;

    // Formatting tanggal sesuai format struk: "21/10/2026 12:00:00"
    final dt = sale.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aksen gerigi potong kertas thermal atas
          _buildPaperTearEdge(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // 1. Logo Struk Hitam Kato POS
                // -------------------------------------------------------------
                Center(
                  child: Image.asset(
                    'assets/Logo/Logo Struk.png',
                    width: 58,
                    height: 46,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_rounded,
                      size: 46,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // 2. Info Toko / Header Struk
                // -------------------------------------------------------------
                const Text(
                  'Kato POS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _receiptFont,
                    fontFamilyFallback: _receiptFontFallback,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Apartemen Gardenia Boulevard, 13900\nPasar Minggu, South Jakarta\n(+62) 800-123',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _receiptFont,
                    fontFamilyFallback: _receiptFontFallback,
                    fontSize: 10.5,
                    color: Colors.black,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                _buildDashedLine(),
                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // 3. Metadata Transaksi (Waktu, Kasir, No. Struk)
                // -------------------------------------------------------------
                _buildInfoLine('Waktu / Tanggal', dateStr),
                const SizedBox(height: 3),
                _buildInfoLine(
                  'Kasir',
                  sale.cashierName.isNotEmpty ? sale.cashierName : 'Shinta',
                ),
                const SizedBox(height: 3),
                _buildInfoLine(
                  'No. Struk',
                  sale.invoiceNumber.isNotEmpty
                      ? sale.invoiceNumber
                      : '0000000000',
                ),
                const SizedBox(height: 10),

                _buildDashedLine(),
                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // 4. Header Kolom Tabel Produk (No.   Produk     Qty   Price)
                // -------------------------------------------------------------
                const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        'No.',
                        style: TextStyle(
                          fontFamily: _receiptFont,
                          fontFamilyFallback: _receiptFontFallback,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Produk',
                        style: TextStyle(
                          fontFamily: _receiptFont,
                          fontFamilyFallback: _receiptFontFallback,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _receiptFont,
                          fontFamilyFallback: _receiptFontFallback,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 76,
                      child: Text(
                        'Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: _receiptFont,
                          fontFamilyFallback: _receiptFontFallback,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildDashedLine(),
                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // 5. Daftar Item Belanja
                // -------------------------------------------------------------
                if (sale.items.isEmpty)
                  _buildEmptyItemRow()
                else
                  for (var i = 0; i < sale.items.length; i++) ...[
                    _buildItemRow(i + 1, sale.items[i]),
                    if (i < sale.items.length - 1) const SizedBox(height: 8),
                  ],
                const SizedBox(height: 10),

                _buildDashedLine(),
                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // 6. Ringkasan Total (Subtotal, Pajak, Discount, Total)
                // -------------------------------------------------------------
                if (showTotals) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 190,
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Subtotal',
                            AppFormatters.formatRupiah(sale.totalAmount),
                          ),
                          const SizedBox(height: 3),
                          _buildSummaryRow('Pajak', 'Rp 0'),
                          const SizedBox(height: 3),
                          _buildSummaryRow('Discount', 'Rp 0'),
                          const SizedBox(height: 3),
                          _buildSummaryRow(
                            'Total',
                            AppFormatters.formatRupiah(sale.totalAmount),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDashedLine(),
                  const SizedBox(height: 10),
                ],

                // -------------------------------------------------------------
                // 7. Informasi Pembayaran (Tunai / QRIS)
                // -------------------------------------------------------------
                if (isCash) ...[
                  _buildFullWidthRow('Metode Bayar', 'Tunai'),
                  const SizedBox(height: 3),
                  _buildFullWidthRow(
                    'Uang Tunai',
                    AppFormatters.formatRupiah(
                      sale.amountPaid > 0 ? sale.amountPaid : sale.totalAmount,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildFullWidthRow(
                    'Uang Kembalian',
                    AppFormatters.formatRupiah(sale.changeAmount),
                  ),
                  const SizedBox(height: 3),
                  _buildFullWidthRow('Status', 'COMPLETED'),
                ] else ...[
                  _buildFullWidthRow('Metode Bayar', 'QRIS'),
                  const SizedBox(height: 3),
                  _buildFullWidthRow(
                    'Ref',
                    sale.terminalCode.isNotEmpty ? sale.terminalCode : '#####',
                  ),
                  const SizedBox(height: 3),
                  _buildFullWidthRow('Status', 'COMPLETED'),
                ],
                const SizedBox(height: 10),

                _buildDashedLine(),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // 8. Footer Ucapan Terima Kasih
                // -------------------------------------------------------------
                const Text(
                  'Terima Kasih!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _receiptFont,
                    fontFamilyFallback: _receiptFontFallback,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // Aksen gerigi potong kertas thermal bawah
          _buildPaperTearEdge(),
        ],
      ),
    );
  }

  /// Gerigi potong kertas thermal (pola checkerboard kecil menyerupai pisau cutter receipt roll)
  Widget _buildPaperTearEdge() {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const squareSize = 6.0;
          final count = (constraints.maxWidth / squareSize).ceil();
          return SizedBox(
            height: squareSize,
            child: Row(
              children: List.generate(count, (index) {
                final isDark = index.isEven;
                return Container(
                  width: squareSize,
                  height: squareSize,
                  color: isDark
                      ? const Color(0xFF262626)
                      : const Color(0xFF555555),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  /// Garis putus-putus horizontal rapi sesuai struk printer thermal
  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 3.5;
        const dashSpace = 2.5;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF6B7280)),
              ),
            );
          }),
        );
      },
    );
  }

  /// Baris informasi metadata transaksi
  Widget _buildInfoLine(String label, String value) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: _receiptFont,
          fontFamilyFallback: _receiptFontFallback,
          fontSize: 10.5,
          color: Colors.black,
        ),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(text: value),
        ],
      ),
    );
  }

  /// Baris produk individual
  Widget _buildItemRow(int index, SaleItemRecord item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$index',
            style: const TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            item.productName,
            style: const TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
              height: 1.25,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${item.qty}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: 76,
          child: Text(
            AppFormatters.formatRupiah(item.subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyItemRow() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '1',
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            '-',
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          width: 76,
          child: Text(
            'Rp 0',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Baris ringkasan subtotal / pajak / discount / total (posisi kanan)
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _receiptFont,
            fontFamilyFallback: _receiptFontFallback,
            fontSize: 10.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Baris full width untuk informasi metode pembayaran
  Widget _buildFullWidthRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _receiptFont,
            fontFamilyFallback: _receiptFontFallback,
            fontSize: 10.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: _receiptFont,
              fontFamilyFallback: _receiptFontFallback,
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
