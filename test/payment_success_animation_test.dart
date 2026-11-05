import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/payment_success_screen.dart';

class _MockSalesNotifier extends SalesNotifier {
  final SaleRecord sample;
  _MockSalesNotifier(this.sample);

  @override
  List<SaleRecord> build() => [sample];

  @override
  Future<void> fetchSalesFromApi({
    String? startDate,
    String? endDate,
    String? status,
  }) async {}
}

void main() {
  final sampleSale = SaleRecord(
    id: 99,
    invoiceNumber: 'TRX-20261023-012',
    createdAt: DateTime(2026, 10, 23, 14, 30),
    totalAmount: 48000,
    cashierName: 'Sekarisma Putri',
    terminalCode: 'KATO-POS-01',
    paymentMethod: PaymentMethod.cash,
    status: TransactionStatus.completed,
    amountPaid: 50000,
    changeAmount: 2000,
    items: const [],
  );

  testWidgets(
      'PaymentSuccessScreen: Centang berkedut animation renders and pulses smoothly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesProvider.overrideWith(() => _MockSalesNotifier(sampleSale)),
        ],
        child: MaterialApp(
          home: PaymentSuccessScreen(saleRecord: sampleSale),
        ),
      ),
    );

    // Initial render
    expect(find.byType(AnimatedSuccessCheckmark), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Pembayaran Berhasil!'), findsOneWidget);
    expect(find.text('No. Transaksi #TRX-20261023-012'), findsOneWidget);

    // Pump entrance animation (550ms)
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Pump pulse / berkedut cycle (heartbeat pulse)
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets(
      'PaymentSuccessScreen: Respects reduced motion accessibility (disableAnimations)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesProvider.overrideWith(() => _MockSalesNotifier(sampleSale)),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              disableAnimations: true,
            ),
            child: PaymentSuccessScreen(saleRecord: sampleSale),
          ),
        ),
      ),
    );

    // When animations are disabled, static checkmark is rendered
    expect(find.byType(AnimatedSuccessCheckmark), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Pembayaran Berhasil!'), findsOneWidget);
  });
}
