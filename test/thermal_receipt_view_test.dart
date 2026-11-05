import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/thermal_receipt_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSale = SaleRecord(
    id: 101,
    invoiceNumber: '0000000000',
    terminalCode: 'TERM-01',
    cashierName: 'Shinta',
    createdAt: DateTime(2026, 10, 21, 12, 0, 0),
    paymentMethod: PaymentMethod.cash,
    status: TransactionStatus.completed,
    totalAmount: 64000,
    amountPaid: 64000,
    changeAmount: 0,
    items: const [
      SaleItemRecord(
        productId: 1,
        productName: 'Mille-Feuille / Vanilla Slice',
        qty: 2,
        unitPrice: 32000,
        sku: 'CAKE-01',
      ),
    ],
  );

  group('ThermalReceiptView Tests', () {
    testWidgets('Renders receipt header, Logo Struk, and store information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: ThermalReceiptView(sale: testSale),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul dan info toko
      expect(find.text('Kato POS'), findsOneWidget);
      expect(
        find.text(
          'Apartemen Gardenia Boulevard, 13900\nPasar Minggu, South Jakarta\n(+62) 800-123',
        ),
        findsOneWidget,
      );

      // Verifikasi metadata transaksi
      expect(find.textContaining('Waktu / Tanggal : 21/10/2026 12:00:00'), findsOneWidget);
      expect(find.textContaining('Kasir : Shinta'), findsOneWidget);
      expect(find.textContaining('No. Struk : 0000000000'), findsOneWidget);

      // Verifikasi kolom tabel
      expect(find.text('No.'), findsOneWidget);
      expect(find.text('Produk'), findsOneWidget);
      expect(find.text('Qty'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);

      // Verifikasi produk
      expect(find.text('Mille-Feuille / Vanilla Slice'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Rp 64.000'), findsWidgets);

      // Verifikasi ringkasan
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Pajak'), findsOneWidget);
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);

      // Verifikasi metode pembayaran
      expect(find.text('Metode Bayar'), findsOneWidget);
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Uang Tunai'), findsOneWidget);
      expect(find.text('Uang Kembalian'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);

      // Verifikasi footer
      expect(find.text('Terima Kasih!'), findsOneWidget);
    });

    testWidgets('Uses Roboto Mono font family across receipt text widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: ThermalReceiptView(sale: testSale),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.style?.fontFamily != null) {
          expect(
            text.style!.fontFamily,
            'Roboto Mono',
            reason: 'Text "${text.data}" should use Roboto Mono font',
          );
        }
      }
    });

    testWidgets('Renders QRIS receipt payment info correctly', (tester) async {
      final qrisSale = SaleRecord(
        id: 102,
        invoiceNumber: 'INV-QRIS-001',
        terminalCode: 'QRIS98231',
        cashierName: 'Sekarisma Putri',
        createdAt: DateTime(2026, 10, 21, 14, 30, 0),
        paymentMethod: PaymentMethod.qris,
        status: TransactionStatus.completed,
        totalAmount: 100000,
        amountPaid: 100000,
        changeAmount: 0,
        items: const [
          SaleItemRecord(
            productId: 2,
            productName: 'Kopi Susu Kato',
            qty: 5,
            unitPrice: 20000,
            sku: 'COF-01',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: ThermalReceiptView(sale: qrisSale),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QRIS'), findsOneWidget);
      expect(find.text('Ref'), findsOneWidget);
      expect(find.text('QRIS98231'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
    });
  });
}
