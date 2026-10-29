import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';

/// Topbar Kato POS sesuai spesifikasi Figma dan referensi gambar.
/// Spesifikasi:
/// - Height: 70px
/// - Background: #FFFFFF
/// - Box Shadow: 0px 0px 20px 0px #0000000D
/// - Padding: horizontal 32px (desktop/tablet) / 16px (mobile), vertical 10px
/// - Kiri: Hamburger 24x24 + Toko badge ("Kato & Co. Sudirman", #5247A1)
/// - Kanan: Status Online (#28A555, border 1px, radius 100) + Notifikasi 40x40 + User profile (Samantha Putri)
class KatoTopbar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogoutPressed;
  final bool isMobile;

  const KatoTopbar({
    super.key,
    this.onMenuPressed,
    this.onLogoutPressed,
    this.isMobile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Samantha Putri';

    final horizontalPad = isMobile ? 16.0 : 32.0;

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // #0000000D
            blurRadius: 20,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -----------------------------------------------------------------
          // Sisi Kiri Topbar
          // -----------------------------------------------------------------
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Hamburger (assets/Icons_SVG/icons_humberger.svg) untuk membuka drawer
                IconButton(
                  onPressed: onMenuPressed,
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  splashRadius: 20,
                  tooltip: 'Menu Utama',
                  icon: SvgPicture.asset(
                    'assets/Icons_SVG/icons_humberger.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF565656),
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.menu_rounded,
                      size: 24,
                      color: Color(0xFF565656),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Badge Toko: "Kato & Co. Sudirman"
                Flexible(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF5247A1).withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/Icons_SVG/icon_toko.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF5247A1),
                            BlendMode.srcIn,
                          ),
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.storefront_outlined,
                            size: 20,
                            color: Color(0xFF5247A1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Kato & Co. Sudirman',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF5247A1),
                              letterSpacing: 0,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status Online Pill (Dipindah ke samping kanan nama toko)
                _buildOnlineStatusPill(isMobile),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // -----------------------------------------------------------------
          // Sisi Kanan Topbar
          // -----------------------------------------------------------------
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icon Notifikasi (40x40, padding 5px, radius 8px)
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/Icons_SVG/Notifications.svg',
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. User Avatar & Nama Pengguna (Samantha Putri)
              PopupMenuButton<String>(
                tooltip: 'Menu Akun',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'logout') {
                    onLogoutPressed?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        Text(
                          user?.role ?? 'Kasir Utama',
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 12,
                            color: Color(0xFF808080),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Keluar dari Kasir',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kotak Ikon User: 30x30, background #5247A1, radius 8px
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5247A1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/Icons_SVG/icon_user.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF565656),
                            letterSpacing: 0,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusPill(bool isMobile) {
    if (isMobile) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x0D28A555),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color(0xFF28A555),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF28A555),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Online',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF28A555),
                letterSpacing: 0,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0D28A555),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF28A555),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF28A555),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Online',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF28A555),
              letterSpacing: 0,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
