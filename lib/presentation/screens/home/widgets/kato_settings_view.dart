import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/services/thermal_printer_service.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Halaman Pengaturan POS Responsif untuk Tablet dan Mobile Phone.
/// Mengelola konfigurasi printer struk (58mm vs 80mm), koneksi, profil outlet, dan preferensi sistem.
class KatoSettingsView extends ConsumerStatefulWidget {
  const KatoSettingsView({super.key});

  @override
  ConsumerState<KatoSettingsView> createState() => _KatoSettingsViewState();
}

class _KatoSettingsViewState extends ConsumerState<KatoSettingsView> {
  final _storeNameController = TextEditingController(text: 'Kato & Co. Sudirman');
  final _storeAddressController =
      TextEditingController(text: 'Menara Sudirman Lt. 1, Jakarta Selatan');
  final _storePhoneController =
      TextEditingController(text: '+62 812-3456-7890');
  final _footerMessageController =
      TextEditingController(text: 'Terima kasih atas kunjungan Anda di Kato & Co!');
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final outlet = ref.read(selectedOutletProvider);
    if (outlet != null) {
      _storeNameController.text = outlet.name;
      if (outlet.address != null && outlet.address!.isNotEmpty) {
        _storeAddressController.text = outlet.address!;
      }
      if (outlet.phone != null && outlet.phone!.isNotEmpty) {
        _storePhoneController.text = outlet.phone!;
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    _footerMessageController.dispose();
    super.dispose();
  }

  void _showTestPrintDialog(BuildContext context, PrinterConfig config) {
    final is58 = config.paperSize == PrinterPaperSize.mm58;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF5247A1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pratinjau Struk (${config.paperSize.label})',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: is58 ? 320 : 420,
              maxHeight: 460,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _storeNameController.text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _storeAddressController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Color(0xFF565656),
                      ),
                    ),
                    Text(
                      'Telp: ${_storePhoneController.text}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Color(0xFF565656),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      is58
                          ? '--------------------------------'
                          : '------------------------------------------------',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INV-20261023-001',
                          style: TextStyle(fontFamily: 'Courier', fontSize: 11),
                        ),
                        Text(
                          is58 ? 'KASIR: SAMANTHA' : 'KASIR: SAMANTHA PUTRI',
                          style: const TextStyle(
                              fontFamily: 'Courier', fontSize: 11),
                        ),
                      ],
                    ),
                    const Text(
                      '23/10/2026 10:15:20 WIB',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                    Text(
                      is58
                          ? '--------------------------------'
                          : '------------------------------------------------',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                    _buildReceiptItemRow(
                      name: 'Kopi Susu Kato Gula Aren',
                      qty: 2,
                      price: 20000,
                      subtotal: 40000,
                      is58: is58,
                    ),
                    const SizedBox(height: 4),
                    _buildReceiptItemRow(
                      name: 'Matcha Latte Special',
                      qty: 1,
                      price: 22000,
                      subtotal: 22000,
                      is58: is58,
                    ),
                    Text(
                      is58
                          ? '--------------------------------'
                          : '------------------------------------------------',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                    _buildReceiptSummaryRow('Subtotal', 'Rp 62.000'),
                    if (config.isTaxEnabled)
                      _buildReceiptSummaryRow('PB1 (10%)', 'Rp 6.200'),
                    _buildReceiptSummaryRow('TOTAL', 'Rp 68.200', isBold: true),
                    _buildReceiptSummaryRow('TUNAI', 'Rp 70.000'),
                    _buildReceiptSummaryRow('KEMBALIAN', 'Rp 1.800'),
                    Text(
                      is58
                          ? '--------------------------------'
                          : '------------------------------------------------',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _footerMessageController.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Color(0xFF565656),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '=== SIMULASI CETAK SUKSES ===',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF28A555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF808080)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mengirim data uji cetak ke printer thermal...',
                      style: TextStyle(fontFamily: 'Open Sans'),
                    ),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                final printerService = ref.read(thermalPrinterServiceProvider);
                final (success, error) = await printerService.printTestReceipt(
                  config: config,
                  storeName: _storeNameController.text,
                  storeAddress: _storeAddressController.text,
                  storePhone: _storePhoneController.text,
                );

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Struk uji coba berhasil dicetak ke ${config.deviceName} (${config.paperSize.label})!',
                        style: const TextStyle(fontFamily: 'Open Sans'),
                      ),
                      backgroundColor: const Color(0xFF28A555),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error ?? 'Gagal mencetak. Pastikan printer terhubung via Bluetooth.',
                        style: const TextStyle(fontFamily: 'Open Sans'),
                      ),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5247A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text(
                'Cetak ke Printer Fisik',
                style: TextStyle(fontFamily: 'Open Sans', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptItemRow({
    required String name,
    required int qty,
    required int price,
    required int subtotal,
    required bool is58,
  }) {
    if (is58) {
      // 58mm: 2 baris agar nama produk tidak terpotong
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '  x$qty @${AppFormatters.formatRupiah(price)}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
              ),
              Text(
                AppFormatters.formatRupiah(subtotal),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 80mm: 1 baris lega
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name x$qty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
            ),
          ),
          Text(
            AppFormatters.formatRupiah(subtotal),
            style: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReceiptSummaryRow(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pengaturan berhasil disimpan ke memori aplikasi.',
          style: TextStyle(fontFamily: 'Open Sans'),
        ),
        backgroundColor: Color(0xFF28A555),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scanBluetoothPrinters() async {
    final printerService = ref.read(thermalPrinterServiceProvider);

    setState(() => _isScanning = true);

    final hasPermission = await printerService.checkPermission();
    if (!mounted) return;
    if (!hasPermission) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin Bluetooth diperlukan untuk mencari printer kasir. Silakan aktifkan izin di pengaturan perangkat.',
            style: TextStyle(fontFamily: 'Open Sans'),
          ),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isEnabled = await printerService.isBluetoothEnabled();
    if (!mounted) return;
    if (!isEnabled) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth belum aktif. Silakan nyalakan Bluetooth HP/Tablet Anda terlebih dahulu.',
            style: TextStyle(fontFamily: 'Open Sans'),
          ),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final devices = await printerService.getPairedDevices();
    if (!mounted) return;
    setState(() => _isScanning = false);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F0FA),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bluetooth_searching_rounded,
                color: Color(0xFF5247A1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pilih Printer Bluetooth',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: devices.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.devices_other_rounded,
                      size: 44,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tidak ada printer Bluetooth ditemukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pastikan printer thermal sudah menyala dan telah dipasangkan (paired) di menu Bluetooth HP/Tablet Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(
                width: 360,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, index) {
                    final d = devices[index];
                    final isCurrent =
                        ref.read(printerConfigProvider).macAddress == d.macAdress;

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF5247A1)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.print_rounded,
                          size: 18,
                          color: isCurrent ? Colors.white : const Color(0xFF565656),
                        ),
                      ),
                      title: Text(
                        d.name.isNotEmpty ? d.name : 'Printer Thermal',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        d.macAdress,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _connectPrinter(d);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5247A1),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isCurrent ? 'Terhubung' : 'Pilih',
                          style: const TextStyle(
                              fontFamily: 'Open Sans', fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(
                  fontFamily: 'Open Sans', color: Color(0xFF808080)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectPrinter(BluetoothInfo device) async {
    final printerService = ref.read(thermalPrinterServiceProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menghubungkan ke ${device.name}...',
            style: const TextStyle(fontFamily: 'Open Sans'),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final isSuccess = await printerService.connect(device.macAdress);
    if (!mounted) return;

    if (isSuccess) {
      ref.read(printerConfigProvider.notifier).setConnectedDevice(
            name: device.name.isNotEmpty ? device.name : 'Printer Bluetooth',
            macAddress: device.macAdress,
            connected: true,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil terhubung ke ${device.name}!',
            style: const TextStyle(fontFamily: 'Open Sans'),
          ),
          backgroundColor: const Color(0xFF28A555),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ref.read(printerConfigProvider.notifier).setConnectionStatus(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghubungkan ke ${device.name}. Pastikan printer menyala dan berada dalam jangkauan Bluetooth.',
            style: const TextStyle(fontFamily: 'Open Sans'),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disconnectPrinter() async {
    final printerService = ref.read(thermalPrinterServiceProvider);
    await printerService.disconnect();
    if (!mounted) return;

    ref.read(printerConfigProvider.notifier).setConnectionStatus(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Koneksi printer Bluetooth diputuskan.',
          style: TextStyle(fontFamily: 'Open Sans'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final printerConfig = ref.watch(printerConfigProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Halaman Responsif (Bebas Overflow di Layar HP maupun Tablet)
            if (isTablet)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan Sistem & POS',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola perangkat printer struk thermal, profil toko, dan tagihan',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showSaveSnackbar(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5247A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pengaturan Sistem & POS',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola perangkat printer struk thermal, profil toko, dan tagihan',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showSaveSnackbar(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5247A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Konten Grid / List Responsif
            if (isTablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom Kiri: Konfigurasi Printer Struk Kasir
                  Expanded(
                    flex: 1,
                    child: _buildPrinterCard(printerConfig),
                  ),
                  const SizedBox(width: 24),
                  // Kolom Kanan: Profil Toko & Tagihan Pajak
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOutletCard(),
                        const SizedBox(height: 20),
                        _buildPaymentTaxCard(printerConfig),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Tampilan Mobile (Kolom Tunggal Menumpuk)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPrinterCard(printerConfig),
                  const SizedBox(height: 16),
                  _buildOutletCard(),
                  const SizedBox(height: 16),
                  _buildPaymentTaxCard(printerConfig),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kartu 1: Konfigurasi Printer Struk Thermal
  // ---------------------------------------------------------------------------
  Widget _buildPrinterCard(PrinterConfig config) {
    return _buildCardWrapper(
      icon: Icons.print_rounded,
      title: 'Konfigurasi Printer Struk Kasir',
      subtitle: 'Sesuaikan ukuran kertas struk, koneksi, dan cetak otomatis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pilihan Ukuran Kertas Thermal (58mm vs 80mm)
          const Text(
            'Ukuran Kertas Thermal Struk',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPaperSizeOption(
                  size: PrinterPaperSize.mm58,
                  isSelected: config.paperSize == PrinterPaperSize.mm58,
                  onTap: () {
                    ref
                        .read(printerConfigProvider.notifier)
                        .updatePaperSize(PrinterPaperSize.mm58);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaperSizeOption(
                  size: PrinterPaperSize.mm80,
                  isSelected: config.paperSize == PrinterPaperSize.mm80,
                  onTap: () {
                    ref
                        .read(printerConfigProvider.notifier)
                        .updatePaperSize(PrinterPaperSize.mm80);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Jalur Koneksi Printer
          const Text(
            'Jalur Koneksi Printer',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final type in PrinterConnectionType.values)
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 16,
                        color: config.connectionType == type
                            ? Colors.white
                            : const Color(0xFF565656),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12,
                          fontWeight: config.connectionType == type
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: config.connectionType == type
                              ? Colors.white
                              : const Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                  selected: config.connectionType == type,
                  selectedColor: const Color(0xFF5247A1),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide(
                    color: config.connectionType == type
                        ? const Color(0xFF5247A1)
                        : const Color(0xFFE5E7EB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(printerConfigProvider.notifier)
                          .updateConnectionType(type);
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Nama Perangkat Printer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: config.isConnected
                        ? const Color(0xFF28A555).withValues(alpha: 0.12)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    config.isConnected
                        ? Icons.check_circle_rounded
                        : Icons.bluetooth_searching_rounded,
                    color: config.isConnected
                        ? const Color(0xFF28A555)
                        : const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.deviceName,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.isConnected
                            ? 'Status: Terhubung via Bluetooth'
                            : 'Status: Belum Terhubung (Silakan Pindai)',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 11,
                          color: config.isConnected
                              ? const Color(0xFF28A555)
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (config.isConnected)
                  OutlinedButton(
                    onPressed: _disconnectPrinter,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Putus',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: _isScanning ? null : _scanBluetoothPrinters,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF5247A1),
                      side: const BorderSide(color: Color(0xFF5247A1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      _isScanning ? 'Memindai...' : 'Pindai Printer',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Toggle Fitur Otomatisasi Struk
          _buildSwitchRow(
            title: 'Cetak Struk Otomatis',
            subtitle: 'Struk otomatis dicetak setelah pembayaran berhasil dikonfirmasi',
            value: config.autoPrintOnCheckout,
            onChanged: (val) {
              ref.read(printerConfigProvider.notifier).toggleAutoPrint(val);
            },
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),
          _buildSwitchRow(
            title: 'Buka Laci Uang (Cash Drawer)',
            subtitle: 'Kirim pulsa sinyal RJ11 untuk membuka laci kasir saat transaksi tunai',
            value: config.openCashDrawer,
            onChanged: (val) {
              ref.read(printerConfigProvider.notifier).toggleCashDrawer(val);
            },
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),
          _buildSwitchRow(
            title: 'Potong Kertas Otomatis (Auto-Cut)',
            subtitle: 'Kirim perintah ESC/POS pemotong kertas pada printer yang mendukung cutter',
            value: config.autoCut,
            onChanged: (val) {
              ref.read(printerConfigProvider.notifier).toggleAutoCut(val);
            },
          ),

          const SizedBox(height: 18),

          // 5. Tombol Tes Cetak Struk
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showTestPrintDialog(context, config),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: const Color(0xFF5247A1),
                side: const BorderSide(color: Color(0xFF5247A1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: Text(
                'Tes Pratinjau & Cetak Struk (${config.paperSize.label})',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSizeOption({
    required PrinterPaperSize size,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5247A1)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  size.label,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected
                        ? const Color(0xFF5247A1)
                        : const Color(0xFF1E1E1E),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF5247A1)
                          : const Color(0xFFD1D5DB),
                      width: isSelected ? 6 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Max ${size.maxChars} Karakter / baris',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Color(0xFF28A555),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              size.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kartu 2: Informasi Toko & Outlet
  // ---------------------------------------------------------------------------
  Widget _buildOutletCard() {
    return _buildCardWrapper(
      icon: Icons.storefront_rounded,
      title: 'Informasi Toko & Header Struk',
      subtitle: 'Informasi yang tercantum pada kop dan footer struk pembayaran',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Nama Toko / Outlet',
            controller: _storeNameController,
            hint: 'Kato & Co. Sudirman',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Alamat Outlet',
            controller: _storeAddressController,
            hint: 'Alamat lengkap outlet...',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Nomor Kontak / WhatsApp',
            controller: _storePhoneController,
            hint: '+62 812-xxxx-xxxx',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Pesan Footer Struk',
            controller: _footerMessageController,
            hint: 'Pesan ucapan terima kasih...',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kartu 3: Pembayaran & Pajak
  // ---------------------------------------------------------------------------
  Widget _buildPaymentTaxCard(PrinterConfig config) {
    return _buildCardWrapper(
      icon: Icons.receipt_long_rounded,
      title: 'Perhitungan Pajak & Struk',
      subtitle: 'Aturan kalkulasi pajak daerah dan format laporan struk',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSwitchRow(
            title: 'Pajak Restoran / PB1 (10%)',
            subtitle: 'Terapkan pajak 10% otomatis pada ringkasan pembayaran',
            value: config.isTaxEnabled,
            onChanged: (val) {
              ref.read(printerConfigProvider.notifier).toggleTax(val);
            },
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),
          _buildSwitchRow(
            title: 'Biaya Layanan (Service Charge 5%)',
            subtitle: 'Tambahkan biaya layanan pada pesanan dine-in',
            value: config.isServiceChargeEnabled,
            onChanged: (val) {
              ref.read(printerConfigProvider.notifier).toggleServiceCharge(val);
            },
          ),
          const Divider(height: 16, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 6),
          const Text(
            'Metode Pembayaran Kasir Aktif',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              Chip(
                label: Text(
                  'Uang Tunai (CASH)',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF28A555),
                  ),
                ),
                backgroundColor: Color(0xFFE8F5E9),
                side: BorderSide.none,
              ),
              Chip(
                label: Text(
                  'QRIS Dinamis / Statis',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5247A1),
                  ),
                ),
                backgroundColor: Color(0xFFF1F0FA),
                side: BorderSide.none,
              ),
            ],
          ),
        ],
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // Komponen Helper
  // ---------------------------------------------------------------------------
  Widget _buildCardWrapper({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: const Color(0xFF5247A1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 12,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF565656),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 13,
            color: Color(0xFF1E1E1E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFFBFBFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF5247A1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 11,
                  color: Color(0xFF808080),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF5247A1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
