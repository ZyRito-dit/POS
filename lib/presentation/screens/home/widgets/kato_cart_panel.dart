import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/dashed_divider.dart';

/// Panel Keranjang / Daftar Pesanan di sebelah kanan (width: ~360px di tablet/desktop)
/// atau disajikan sebagai Bottom Sheet pada perangkat seluler.
class KatoCartPanel extends ConsumerStatefulWidget {
  final bool isBottomSheet;

  const KatoCartPanel({
    super.key,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<KatoCartPanel> createState() => _KatoCartPanelState();
}

class _KatoCartPanelState extends ConsumerState<KatoCartPanel> {
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final selectedPaymentMethod = ref.watch(selectedPaymentMethodProvider);

    final subtotal = cartItems.fold<int>(0, (sum, i) => sum + i.subtotal);
    final tax = 0;
    final total = (subtotal + tax).clamp(0, 999999999);

    return Container(
      width: widget.isBottomSheet ? double.infinity : 360,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: widget.isBottomSheet
            ? null
            : const Border(
                left: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 1. Header: Daftar Pesanan + Badge + Hapus Semua
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Daftar Pesanan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F0FA),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF5247A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: cartItems.isEmpty
                      ? null
                      : () => ref.read(cartProvider.notifier).clear(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  label: const Text(
                    'Hapus Semua',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          // 2. Konten Keranjang & Pembayaran (Mengalir dari atas ke bawah dengan ruang kosong di bagian bawah)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cartItems.isEmpty) ...[
                    // Tampilan Saat Belum Ada Pesanan (Sesuai referensi gambar)
                    const SizedBox(height: 32),
                    const Center(
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 52,
                        color: Color(0xFF565656),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Belum ada pesanan.',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF565656),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Pilih produk dari katalog di sebelah kiri untuk\nmenambahkan pesanan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xFF808080),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Daftar Item Pesanan
                    for (int i = 0; i < cartItems.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildCartItemCard(cartItems[i]),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 20),
                  ],

                  // Metode Pembayaran (Diletakkan di atas Detail Pembayaran)
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodButton(
                          label: 'Tunai',
                          isSelected: selectedPaymentMethod == PaymentMethod.cash,
                          onTap: () {
                            ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .state = PaymentMethod.cash;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentMethodButton(
                          label: 'QRIS',
                          isSelected: selectedPaymentMethod == PaymentMethod.qris,
                          onTap: () {
                            ref
                                .read(selectedPaymentMethodProvider.notifier)
                                .state = PaymentMethod.qris;
                          },
                        ),
                      ),
                    ],
                  ),

                  if (cartItems.isNotEmpty) ...[
                    const SizedBox(height: 20),

                    // Detail Pembayaran (Card Container)
                    const Text(
                      'Detail Pembayaran',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', AppFormatters.formatRupiah(subtotal)),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Pajak', AppFormatters.formatRupiah(tax)),
                          const SizedBox(height: 12),
                          const DashedDivider(color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Total',
                            AppFormatters.formatRupiah(total),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Tombol "Proses Pembayaran"
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: cartItems.isEmpty
                          ? null
                          : () {
                              if (widget.isBottomSheet && context.mounted) {
                                Navigator.of(context).pop();
                              }
                              final method = ref.read(selectedPaymentMethodProvider);
                              if (method == PaymentMethod.cash) {
                                context.push(AppRoutes.paymentCash);
                              } else {
                                context.push(AppRoutes.paymentQris);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5247A1),
                        disabledBackgroundColor:
                            const Color(0xFF5247A1).withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proses Pembayaran',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ruang kosong ekstra di bawah tombol sesuai desain
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kode: ${item.product.sku}',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF808080),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppFormatters.formatRupiah(item.subtotal),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1E1E1E),
                ),
              ),

              // Stepper: [-]  qty  [+]
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .addOrUpdate(item.product, delta: -1);
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.remove,
                        size: 14,
                        color: Color(0xFF565656),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.qty}',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .addOrUpdate(item.product, delta: 1);
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5247A1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontSize: isBold ? 14 : 13,
            color: isBold ? const Color(0xFF1E1E1E) : const Color(0xFF565656),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            fontSize: isBold ? 14 : 13,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF5247A1) : const Color(0xFFFFFFFF),
          side: const BorderSide(color: Color(0xFF5247A1), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF5247A1),
          ),
        ),
      ),
    );
  }
}
