import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/transactions_view.dart';

class _MockSalesNotifier extends SalesNotifier {
  @override
  List<SaleRecord> build() => const [];

  @override
  Future<void> fetchSalesFromApi({
    String? startDate,
    String? endDate,
    String? status,
  }) async {}
}

void main() {
  testWidgets(
      'TransactionsView: Empty search result under constrained height (software keyboard) does not overflow',
      (WidgetTester tester) async {
    // Simulate constrained viewport when on-screen keyboard is open (e.g. 600x320)
    tester.view.physicalSize = const Size(600, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          salesProvider.overrideWith(() => _MockSalesNotifier()),
        ],
        child: const MaterialApp(
          home: TransactionsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify search field is present and type a search query
    final searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);

    await tester.enterText(searchFinder, 'NonExistentTransaction999');
    await tester.pumpAndSettle();

    // Verify empty state text is rendered with zero RenderFlex overflow
    expect(find.text('Tidak ada data transaksi yang sesuai.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
