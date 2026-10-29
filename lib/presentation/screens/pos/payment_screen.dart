import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/cash_payment_screen.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/qris_payment_screen.dart';

export 'cash_payment_screen.dart';
export 'qris_payment_screen.dart';

/// Router wrapper untuk Halaman Pembayaran Kato POS.
/// Menampilkan [CashPaymentScreen] jika metode pembayaran Tunai (Gambar 1)
/// atau [QrisPaymentScreen] jika metode pembayaran QRIS (Gambar 2).
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(selectedPaymentMethodProvider);

    if (method == PaymentMethod.qris) {
      return const QrisPaymentScreen();
    }
    return const CashPaymentScreen();
  }
}
