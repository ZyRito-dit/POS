import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';

class SidebarMenuItem {
  final int index;
  final String label;
  final String svgPath;
  final IconData fallbackIcon;

  const SidebarMenuItem({
    required this.index,
    required this.label,
    required this.svgPath,
    required this.fallbackIcon,
  });
}

/// Daftar menu navigasi Kato POS di Drawer (Katalog, Transaksi, Pengaturan):
/// 1. Katalog (icons_katalog.svg)
/// 2. Transaksi (icons_transaksi.svg)
/// 3. Pengaturan (icons_settings.svg) — termasuk konfigurasi printer struk thermal
const katoDrawerMenuItems = [
  SidebarMenuItem(
    index: 0,
    label: 'Katalog',
    svgPath: 'assets/Icons_SVG/icons_katalog.svg',
    fallbackIcon: Icons.grid_view_rounded,
  ),
  SidebarMenuItem(
    index: 1,
    label: 'Transaksi',
    svgPath: 'assets/Icons_SVG/icons_transaksi.svg',
    fallbackIcon: Icons.receipt_long_rounded,
  ),
  SidebarMenuItem(
    index: 3,
    label: 'Pengaturan',
    svgPath: 'assets/Icons_SVG/icons_settings.svg',
    fallbackIcon: Icons.settings_outlined,
  ),
];

/// Daftar menu rail/desktop lengkap
const katoMenuItems = [
  SidebarMenuItem(
    index: 0,
    label: 'Katalog',
    svgPath: 'assets/Icons_SVG/icons_katalog.svg',
    fallbackIcon: Icons.grid_view_rounded,
  ),
  SidebarMenuItem(
    index: 1,
    label: 'Transaksi',
    svgPath: 'assets/Icons_SVG/icons_transaksi.svg',
    fallbackIcon: Icons.receipt_long_rounded,
  ),
  SidebarMenuItem(
    index: 2,
    label: 'Stok',
    svgPath: 'assets/Icons_SVG/icons_stok.svg',
    fallbackIcon: Icons.inventory_2_outlined,
  ),
  SidebarMenuItem(
    index: 3,
    label: 'Pengaturan',
    svgPath: 'assets/Icons_SVG/icons_settings.svg',
    fallbackIcon: Icons.settings_outlined,
  ),
];

/// Sidebar vertikal responsif sesuai referensi desain Kato POS.
/// - Tablet View: Sidebar ramping (width: 80px) dengan ikon SVG dalam kotak 40x40 (radius 8px, gap 10px).
/// - Drawer View: Tampilan drawer samping untuk mobile Android/HP dengan label teks menu yang jelas.
class KatoSidebar extends ConsumerWidget {
  final int activeIndex;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onRefresh;
  final bool isDrawer;

  const KatoSidebar({
    super.key,
    this.activeIndex = 0,
    this.onIndexChanged,
    this.onLogout,
    this.onRefresh,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDrawer) {
      return _buildDrawerContent(context, ref);
    }
    return _buildRailContent(context, ref);
  }

  // ---------------------------------------------------------------------------
  // Tampilan 1: Tablet Sidebar Ramping (Width: 80px)
  // ---------------------------------------------------------------------------
  Widget _buildRailContent(BuildContext context, WidgetRef ref) {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          right: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 14),

            // 1. Logo Kato POS
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/Logo/logo_kato_pos.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5247A1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 2. Daftar 4 Menu Utama (Katalog, Transaksi, Stok, Pengaturan)
            // Format spesifikasi: width 40, height 40, border-radius 8px, padding 5px, gap 10px
            for (int i = 0; i < katoMenuItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildRailItem(
                item: katoMenuItems[i],
                isSelected: activeIndex == katoMenuItems[i].index,
                onTap: () => onIndexChanged?.call(katoMenuItems[i].index),
              ),
            ],

            const Spacer(),

            // 3. Theme Toggle (Light / Dark)
            IconButton(
              onPressed: () {
                final current = ref.read(themeModeProvider);
                ref.read(themeModeProvider.notifier).state =
                    current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              },
              tooltip: context.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
              icon: Icon(
                context.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: const Color(0xFF808080),
                size: 22,
              ),
            ),

            const SizedBox(height: 8),

            // 4. Logout Action
            IconButton(
              onPressed: onLogout,
              tooltip: 'Keluar',
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF808080),
                size: 22,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required SidebarMenuItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: item.label,
      preferBelow: false,
      textStyle: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5247A1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x335247A1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            item.svgPath,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? Colors.white : const Color(0xFF1E1E1E),
              BlendMode.srcIn,
            ),
            placeholderBuilder: (context) => Icon(
              item.fallbackIcon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
            ),
            errorBuilder: (context, error, stackTrace) => Icon(
              item.fallbackIcon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tampilan 2: Drawer Content Sesuai Desain Kato POS
  // Spesifikasi: width: 330, border-right: 1px, gap: 20px
  // ---------------------------------------------------------------------------
  Widget _buildDrawerContent(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isShort = screenHeight < 520;

    return Container(
      width: 330,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDrawerHeader(context, ref, isShort: isShort),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: _buildDrawerBody(context, ref, isShort: isShort),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header ungu (#5247A1) dengan lengkungan sudut kanan bawah (radius 100px)
  /// Spesifikasi: width: 330, height: 175, padding: 5px 24px 24px 24px, gap: 20px, radius: 100px
  Widget _buildDrawerHeader(BuildContext context, WidgetRef ref, {bool isShort = false}) {
    final connectivity = ref.watch(posConnectivityProvider);
    final isOnline = connectivity.isOnline;
    final dotColor = isOnline ? const Color(0xFF28A555) : const Color(0xFFDC2626);
    final labelText = isOnline ? 'Online' : 'Offline';

    final user = ref.watch(currentUserProvider);
    final userName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (connectivity.cashierName.isNotEmpty
            ? connectivity.cashierName
            : 'Sekarisma Putri');
    final role = user?.role?.isNotEmpty == true ? user!.role! : 'Kasir';
    final selectedOutlet = ref.watch(selectedOutletProvider);
    final outletName = selectedOutlet?.name.isNotEmpty == true
        ? selectedOutlet!.name
        : (connectivity.outletName.isNotEmpty
            ? connectivity.outletName
            : 'Kopi Kato - Cabang Sudirman');

    return Container(
      width: 330,
      constraints: BoxConstraints(minHeight: isShort ? 100 : 180),
      decoration: BoxDecoration(
        color: const Color(0xFF5247A1),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(isShort ? 40 : 100),
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isShort ? 20 : 24,
            isShort ? 10 : 20,
            isShort ? 20 : 24,
            isShort ? 12 : 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris 1: Status Online di kiri & Ikon Hamburger di kanan (tutup drawer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pill Status Online / Offline
                  Tooltip(
                    message: connectivity.friendlyMessage.isNotEmpty
                        ? connectivity.friendlyMessage
                        : (isOnline
                            ? 'Perangkat kasir terhubung secara online'
                            : 'Perangkat kasir offline'),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(posConnectivityProvider.notifier)
                            .checkConnectivity();
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              labelText,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dotColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Ikon Hamburger (assets/Icons_SVG/icons_humberger.svg)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Tutup Menu',
                    icon: SvgPicture.asset(
                      'assets/Icons_SVG/icons_humberger.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isShort ? 8 : 18),

              // Baris 2: Avatar Kotak Putih + Badge Toko & Info Kasir
              // Avatar lebar 40px, jarak 12px -> teks kasir mulai tepat pada offset x=76px (24+40+12)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar dalam kotak putih (radius 10) dengan ikon user ungu
                  Container(
                    width: isShort ? 34 : 40,
                    height: isShort ? 34 : 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isShort ? 8 : 10),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/Icons_SVG/icon_user.svg',
                      width: isShort ? 18 : 22,
                      height: isShort ? 18 : 22,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF5247A1),
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF5247A1),
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Detail Toko & Nama Kasir
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge Toko
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/Icons_SVG/icon_toko.svg',
                                width: 13,
                                height: 13,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.storefront_outlined,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  outletName,
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Nama Kasir
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 1),

                        // Peran
                        Text(
                          role,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Body Drawer: Tombol Sinkronisasi, 2 Menu Utama (Katalog & Transaksi), dan Tombol Keluar
  /// Layout sejajar dengan profil (gap: 20px, margin horizontal: 24px)
  Widget _buildDrawerBody(BuildContext context, WidgetRef ref, {bool isShort = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isShort ? 20 : 24,
        isShort ? 12 : 20,
        isShort ? 20 : 24,
        isShort ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Tombol Sinkronisasi (#5247A1)
          InkWell(
            onTap: () {
              Navigator.of(context).maybePop();
              onRefresh?.call();
              ref.read(posProductsProvider.notifier).fetchCatalog(
                    outletId: ref.read(selectedOutletProvider)?.id ??
                        ref.read(currentUserProvider)?.outletId ??
                        1,
                  );
              ref.invalidate(categoriesProvider);
              ref.read(salesProvider.notifier).fetchSalesFromApi();
              ref.read(posConnectivityProvider.notifier).checkConnectivity();
              ref.read(notificationsProvider.notifier).fetchNotifications();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sinkronisasi data berhasil',
                    style: TextStyle(fontFamily: 'Open Sans'),
                  ),
                  backgroundColor: Color(0xFF5247A1),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: isShort ? 34 : 38,
              padding: EdgeInsets.symmetric(horizontal: isShort ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF5247A1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.sync_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sinkronisasi',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isShort ? 12 : 20),

          // 2. Daftar Menu Navigasi: Hanya Katalog & Transaksi (gap: 20px)
          // Slot ikon selebar 40px + jarak 12px mensejajarkan teks menu tepat dengan teks profil
          for (int i = 0; i < katoDrawerMenuItems.length; i++) ...[
            if (i > 0) SizedBox(height: isShort ? 10 : 20),
            _buildDrawerMenuItem(
              item: katoDrawerMenuItems[i],
              isSelected: activeIndex == katoDrawerMenuItems[i].index,
              isShort: isShort,
              onTap: () {
                Navigator.of(context).maybePop();
                onIndexChanged?.call(katoDrawerMenuItems[i].index);
              },
            ),
          ],

          SizedBox(height: isShort ? 14 : 20),

          // 3. Tombol Keluar (Merah #DC2626)
          SizedBox(
            width: double.infinity,
            height: isShort ? 38 : 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
                onLogout?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: isShort ? 12 : 24),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required SidebarMenuItem item,
    required bool isSelected,
    required VoidCallback onTap,
    bool isShort = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isShort ? 2 : 4),
        child: Row(
          children: [
            // Slot ikon selebar 40px sejajar vertikal dengan avatar kotak 40px di header
            SizedBox(
              width: isShort ? 34 : 40,
              height: isShort ? 34 : 40,
              child: Center(
                child: SvgPicture.asset(
                  item.svgPath,
                  width: isShort ? 19 : 22,
                  height: isShort ? 19 : 22,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF5247A1)
                        : const Color(0xFF262626),
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => Icon(
                    item.fallbackIcon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF5247A1)
                        : const Color(0xFF262626),
                  ),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    item.fallbackIcon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF5247A1)
                        : const Color(0xFF262626),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Teks label menu sejajar vertikal dengan nama profil di header
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF5247A1)
                    : const Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}