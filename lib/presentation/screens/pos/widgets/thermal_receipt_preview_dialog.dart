import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/services/thermal_printer_service.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/thermal_receipt_view.dart';

/// Dialog Modal Pratinjau Struk Termal 58mm sesuai desain Gambar 2 & Gambar 3.
/// Mengakomodasi kebutuhan operasional saat ini di mana aplikasi belum terhubung
/// langsung ke mesin printer fisik, sehingga kasir dapat memverifikasi isi struk di layar.
class ThermalReceiptPreviewDialog extends ConsumerWidget {
  final SaleRecord sale;
  final bool showTotals;

  const ThermalReceiptPreviewDialog({
    super.key,
    required this.sale,
    this.showTotals = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Kertas Struk Thermal 58mm
              ThermalReceiptView(
                sale: sale,
                showTotals: showTotals,
              ),
              const SizedBox(height: 16),

              // 2. Bar Tombol Aksi di Bawah Struk
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF5247A1), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5247A1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final printerConfig = ref.read(printerConfigProvider);
                          if (printerConfig.isConnected) {
                            await ref.read(thermalPrinterServiceProvider).printSaleReceipt(
                                  config: printerConfig,
                                  sale: sale,
                                  storeName: 'Kato POS',
                                  storeAddress: 'Apartemen Gardenia Boulevard, 13900\nPasar Minggu, South Jakarta',
                                  storePhone: '(+62) 800-123',
                                  footerMessage: 'Terima Kasih!',
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Struk berhasil dikirim ke printer thermal.'),
                                  backgroundColor: Color(0xFF28A555),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printer thermal Bluetooth belum terhubung. Mode pratinjau aktif.'),
                                  backgroundColor: Color(0xFF5247A1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text(
                          'Cetak Ulang',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A409A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
