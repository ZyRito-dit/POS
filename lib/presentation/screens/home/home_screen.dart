import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_cart_panel.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_catalog_view.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_sidebar.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_topbar.dart';
import 'package:pos_apps_umkm/presentation/screens/home/widgets/kato_settings_view.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/catalog_view.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/transactions_view.dart';

/// Halaman Home / Kasir Kato POS sesuai referensi desain Figma.
/// - Sidebar vertikal ramping (80px)
/// - Topbar Kato POS (70px)
/// - Tampilan Katalog Makanan (Search bar, horizontal category chips, grid menu)
/// - Panel Daftar Pesanan (Keranjang, ringkasan, metode bayar Tunai/QRIS, tombol bayar)
/// - Responsif di layar tablet (landscape & portrait) dan smartphone mobile.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeNavIndex = 0;

  void _handleLogout() {
    ref.read(loginProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _openMobileCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Expanded(
                child: KatoCartPanel(isBottomSheet: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Khusus halaman Transaksi (_activeNavIndex == 1):
    // Tampilkan TransactionsView secara penuh tanpa KatoTopbar (tanpa hamburger, bell, dan account).
    // TransactionsView memiliki topbar sendiri yang ringkas berisi tombol kembali (<-) ke beranda.
    if (_activeNavIndex == 1) {
      return _buildSecondaryView(_activeNavIndex);
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    // Breakpoint tablet/desktop: >= 850px menampilkan 3-kolom penuh (sidebar + katalog + cart)
    final isWide = screenWidth >= 850;

    if (isWide) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFFBFBFD),
        drawer: Drawer(
          width: 330,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: KatoSidebar(
            isDrawer: true,
            activeIndex: _activeNavIndex,
            onIndexChanged: (idx) {
              setState(() => _activeNavIndex = idx);
            },
            onLogout: _handleLogout,
          ),
        ),
        body: Column(
          children: [
            // Topbar (70px) - Posisi penuh dari tepi kiri dengan background ungu #5247A1
            Container(
              color: const Color(0xFF5247A1),
              child: SafeArea(
                bottom: false,
                child: KatoTopbar(
                  isMobile: false,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  onLogoutPressed: _handleLogout,
                ),
              ),
            ),

            // Area Kerja - Katalog Makanan & Panel Keranjang Pesanan (Dilindungi SafeArea bawah agar tidak tertutup nav bar / Taskbar tablet)
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
                left: true,
                right: true,
                child: _activeNavIndex == 0
                    ? Row(
                        children: [
                          // Grid Katalog Makanan (Tengah)
                          const Expanded(
                            child: KatoCatalogView(isMobile: false),
                          ),

                          // Panel Daftar Pesanan (Kanan - 360px)
                          const KatoCartPanel(isBottomSheet: false),
                        ],
                      )
                    : _buildSecondaryView(_activeNavIndex),
              ),
            ),
          ],
        ),
      );
    }

    // -----------------------------------------------------------------------
    // Tampilan Mobile Phone (< 850px)
    // -----------------------------------------------------------------------
    final totalItems = ref.watch(cartTotalItemsProvider);
    final total = ref.watch(cartTotalAmountProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFBFBFD),
      drawer: Drawer(
        width: 330,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: KatoSidebar(
          isDrawer: true,
          activeIndex: _activeNavIndex,
          onIndexChanged: (idx) {
            setState(() => _activeNavIndex = idx);
          },
          onLogout: _handleLogout,
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: const Color(0xFF5247A1),
          child: SafeArea(
            bottom: false,
            child: KatoTopbar(
              isMobile: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              onLogoutPressed: _handleLogout,
            ),
          ),
        ),
      ),
      body: _activeNavIndex == 0
          ? Column(
              children: [
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: totalItems == 0,
                    child: const KatoCatalogView(isMobile: true),
                  ),
                ),

                // Sticky Bottom Cart Summary Bar jika ada pesanan di keranjang
                if (totalItems > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$totalItems Item di Keranjang',
                                    style: const TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF808080),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppFormatters.formatRupiah(total),
                                    style: const TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5247A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _openMobileCartBottomSheet(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5247A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Lihat Pesanan',
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : SafeArea(
              top: false,
              child: _buildSecondaryView(_activeNavIndex),
            ),
    );
  }

  Widget _buildSecondaryView(int index) {
    switch (index) {
      case 1:
        return TransactionsView(
          onBackPressed: () {
            setState(() => _activeNavIndex = 0);
          },
        );
      case 2:
        return const CatalogView();
      case 3:
        return const KatoSettingsView();
      default:
        return const Center(child: Text('Menu'));
    }
  }
}
