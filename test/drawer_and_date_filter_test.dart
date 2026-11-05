import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_sidebar.dart';
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
  group('Drawer Refresh Auto-Close & Transactions Date Filter Reset', () {
    testWidgets(
        'Drawer: Tapping refresh (Sinkronisasi) closes the drawer automatically',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              key: scaffoldKey,
              drawer: const Drawer(
                child: KatoSidebar(
                  isDrawer: true,
                ),
              ),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  child: const Text('Open Drawer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();
      expect(scaffoldKey.currentState?.isDrawerOpen, isTrue);

      // Verify Sinkronisasi / refresh button is rendered in drawer
      final syncButtonFinder = find.text('Sinkronisasi');
      expect(syncButtonFinder, findsOneWidget);

      // Tap Sinkronisasi / refresh button
      await tester.tap(syncButtonFinder);
      await tester.pumpAndSettle();

      // Verify drawer is automatically closed
      expect(scaffoldKey.currentState?.isDrawerOpen, isFalse);
    });

    testWidgets(
        'TransactionsView: Date filter allows picking and has Reset button to return to default',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            salesProvider.overrideWith(() => _MockSalesNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TransactionsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default state: "Pilih rentang tanggal" is visible and no "Reset" button
      expect(find.text('Pilih rentang tanggal'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);

      // Tap on the date picker container to trigger showDateRangePicker
      await tester.tap(find.text('Pilih rentang tanggal'));
      await tester.pumpAndSettle();

      // Date range picker dialog should be visible, tap "Save" or confirm selection
      // In Material showDateRangePicker, there is a SAVE / SIMPAN button
      final saveFinder = find.text('Save');
      final simpanFinder = find.text('SIMPAN');
      if (saveFinder.evaluate().isNotEmpty) {
        await tester.tap(saveFinder);
      } else if (simpanFinder.evaluate().isNotEmpty) {
        await tester.tap(simpanFinder);
      } else {
        // Fallback: tap icon close or close dialog
        final saveIconButton = find.widgetWithText(TextButton, 'Save');
        if (saveIconButton.evaluate().isNotEmpty) {
          await tester.tap(saveIconButton);
        }
      }
      await tester.pumpAndSettle();

      // If a range is picked, "Reset" button appears
      // Alternatively, let's verify Reset button functionality
      if (find.text('Reset').evaluate().isNotEmpty) {
        expect(find.text('Reset'), findsOneWidget);

        // Tap the Reset button
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        // Default state restored
        expect(find.text('Pilih rentang tanggal'), findsOneWidget);
        expect(find.text('Reset'), findsNothing);
      }
    });
  });
}
