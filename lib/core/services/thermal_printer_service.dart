import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Service pengendali printer struk kasir thermal (ESC/POS) melalui Bluetooth.
/// Mendukung ukuran kertas 58mm (32 karakter) dan 80mm (48 karakter).
class ThermalPrinterService {
  CapabilityProfile? _profile;

  Future<CapabilityProfile> _getProfile() async {
    _profile ??= await CapabilityProfile.load();
    return _profile!;
  }

  /// Memeriksa apakah izin Bluetooth telah diberikan (khususnya Android 12+).
  Future<bool> checkPermission() async {
    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (e) {
      debugPrint('[PrinterService] Error checkPermission: $e');
      return false;
    }
  }

  /// Memeriksa apakah Bluetooth perangkat sedang aktif (ON).
  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('[PrinterService] Error isBluetoothEnabled: $e');
      return false;
    }
  }

  /// Mengambil daftar perangkat printer Bluetooth yang telah terhubung/berpasangan (Paired).
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint('[PrinterService] Error getPairedDevices: $e');
      return [];
    }
  }

  /// Memeriksa status koneksi saat ini ke printer.
  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      debugPrint('[PrinterService] Error isConnected: $e');
      return false;
    }
  }

  /// Menghubungkan ke printer via MAC Address Bluetooth.
  Future<bool> connect(String macAddress) async {
    try {
      final isSuccess =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return isSuccess;
    } catch (e) {
      debugPrint('[PrinterService] Error connect to $macAddress: $e');
      return false;
    }
  }

  /// Memutuskan koneksi printer Bluetooth.
  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (e) {
      debugPrint('[PrinterService] Error disconnect: $e');
      return false;
    }
  }

  /// Mengirim raw bytes perintah ESC/POS ke printer.
  Future<bool> writeBytes(List<int> bytes) async {
    try {
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('[PrinterService] Error writeBytes: $e');
      return false;
    }
  }

  /// Mencetak lembar Uji Coba Struk Kasir (Test Print).
  Future<(bool, String?)> printTestReceipt({
    required PrinterConfig config,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final connected = await isConnected();
    if (!connected) {
      return (false, 'Printer belum terhubung via Bluetooth.');
    }

    try {
      final profile = await _getProfile();
      final is58 = config.paperSize == PrinterPaperSize.mm58;
      final generator =
          Generator(is58 ? PaperSize.mm58 : PaperSize.mm80, profile);

      List<int> bytes = [];

      // Header Toko
      bytes += generator.text(
        storeName.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Telp: $storePhone',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr(ch: '-');

      // Informasi Uji Coba
      bytes += generator.text(
        '*** UJI CETAK STRUK KASIR ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Format Kertas: ${config.paperSize.label} (${config.paperSize.maxChars} Karakter/Baris)',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Jalur Koneksi: ${config.connectionType.label}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr(ch: '-');

      // Contoh Item Pesanan
      bytes += generator.row([
        PosColumn(
          text: 'Es Kopi Kato (2x)',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '50.000',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Matcha Latte (1x)',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '22.000',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.hr(ch: '=');
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL TAGIHAN',
          width: 7,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: 'Rp 72.000',
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.hr(ch: '-');

      // Status
      bytes += generator.text(
        'STATUS: SUKSES TERHUBUNG',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Terima kasih - Kato POS',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Buka Laci Kasir jika diaktifkan
      if (config.openCashDrawer) {
        bytes += generator.drawer();
      }

      // Potong Kertas
      bytes += generator.feed(2);
      if (config.autoCut) {
        bytes += generator.cut();
      }

      final success = await writeBytes(bytes);
      if (success) {
        return (true, null);
      } else {
        return (false, 'Gagal mengirim data ke printer.');
      }
    } catch (e) {
      return (false, 'Terjadi kesalahan saat mencetak: $e');
    }
  }

  /// Mencetak struk transaksi penjualan kasir nyata setelah checkout.
  Future<(bool, String?)> printSaleReceipt({
    required PrinterConfig config,
    required SaleRecord sale,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String footerMessage,
  }) async {
    final connected = await isConnected();
    if (!connected) {
      return (false, 'Printer belum terhubung.');
    }

    try {
      final profile = await _getProfile();
      final is58 = config.paperSize == PrinterPaperSize.mm58;
      final generator =
          Generator(is58 ? PaperSize.mm58 : PaperSize.mm80, profile);

      List<int> bytes = [];

      // Header Toko
      bytes += generator.text(
        storeName.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'Telp: $storePhone',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr(ch: '-');

      // Info Transaksi
      bytes += generator.row([
        PosColumn(
          text: 'No: ${sale.invoiceNumber}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: AppFormatters.formatDateTime(sale.createdAt),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(
          text: 'Kasir: ${sale.cashierName}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'Bayar: ${sale.paymentMethod.code}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.hr(ch: '-');

      // Daftar Item
      for (final item in sale.items) {
        bytes += generator.row([
          PosColumn(
            text: '${item.productName} (${item.qty}x)',
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: AppFormatters.formatRupiah(item.subtotal),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr(ch: '=');

      // Ringkasan Pembayaran
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: AppFormatters.formatRupiah(sale.totalAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Bayar (${sale.paymentMethod.code})', width: 6),
        PosColumn(
          text: AppFormatters.formatRupiah(sale.amountPaid),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (sale.changeAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Kembalian', width: 6),
          PosColumn(
            text: AppFormatters.formatRupiah(sale.changeAmount),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.hr(ch: '-');

      // Catatan Kaki (Footer Message)
      if (footerMessage.isNotEmpty) {
        bytes += generator.text(
          footerMessage,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.text(
        'LUNAS - TERIMA KASIH',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      // Pulsa Buka Laci Kasir
      if (config.openCashDrawer) {
        bytes += generator.drawer();
      }

      // Potong Kertas
      bytes += generator.feed(2);
      if (config.autoCut) {
        bytes += generator.cut();
      }

      final success = await writeBytes(bytes);
      if (success) {
        return (true, null);
      } else {
        return (false, 'Gagal mencetak struk.');
      }
    } catch (e) {
      return (false, 'Terjadi kesalahan cetak struk: $e');
    }
  }
}

/// Provider singleton untuk [ThermalPrinterService].
final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  return ThermalPrinterService();
});

/// State notifier untuk status koneksi Bluetooth printer saat ini.
class PrinterConnectionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setConnected(bool value) => state = value;
}

final printerConnectedProvider =
    NotifierProvider<PrinterConnectionNotifier, bool>(
  PrinterConnectionNotifier.new,
);
