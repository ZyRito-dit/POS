import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';

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
        : 'Sekarisma Putri';
    final rawRole = user?.role;
    final String userRole;
    if (rawRole != null && rawRole.isNotEmpty) {
      userRole = rawRole.toUpperCase() == 'CASHIER' ? 'Kasir' : rawRole;
    } else {
      userRole = 'Kasir';
    }

    final selectedOutlet = ref.watch(selectedOutletProvider);
    final accessibleOutlets = ref.watch(accessibleOutletsProvider);
    final outletName = selectedOutlet?.name.isNotEmpty == true
        ? selectedOutlet!.name
        : 'Kato & Co. Sudirman';
    final hasMultipleOutlets = accessibleOutlets.length > 1;

    final horizontalPad = isMobile ? 16.0 : 32.0;

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF5247A1),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.menu_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Badge Toko / Outlet (Format Figma: height 29, padding 5px 15px, radius 100, background #FFFFFF1A)
                Flexible(
                  child: InkWell(
                    onTap: hasMultipleOutlets
                        ? () => _showOutletSelector(context, ref)
                        : null,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      height: 29,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              outletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.white,
                                letterSpacing: 0,
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (hasMultipleOutlets) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 10),

                // Status Online Pill (Dipindah ke samping kanan nama toko)
                _buildOnlineStatusPill(context, ref, isMobile),
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
              // 1. Icon Notifikasi (Lonceng Putih)
              Container(
                width: isMobile ? 32 : 36,
                height: isMobile ? 32 : 36,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/Icons_SVG/Notifications.svg',
                  width: isMobile ? 20 : 22,
                  height: isMobile ? 20 : 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.notifications_none_rounded,
                    size: isMobile ? 20 : 22,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),

              // 2. User Avatar Box (Kotak Putih dengan Ikon User Ungu)
              Container(
                width: isMobile ? 32 : 36,
                height: isMobile ? 32 : 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/Icons_SVG/icon_user.svg',
                  width: isMobile ? 16 : 18,
                  height: isMobile ? 16 : 18,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF5247A1),
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person_outline_rounded,
                    size: isMobile ? 18 : 20,
                    color: const Color(0xFF5247A1),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 10),

                // 3. User Name & Role (Sekarisma Putri / Kasir)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusPill(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
  ) {
    final connectivity = ref.watch(posConnectivityProvider);
    final isOnline = connectivity.isOnline;
    final dotColor = isOnline ? const Color(0xFF28A555) : const Color(0xFFDC2626);
    final labelText = isOnline ? 'Online' : 'Offline';

    return Tooltip(
      message: connectivity.friendlyMessage.isNotEmpty
          ? connectivity.friendlyMessage
          : (isOnline
              ? 'Perangkat kasir terhubung secara online'
              : 'Perangkat kasir offline'),
      child: InkWell(
        onTap: () {
          ref.read(posConnectivityProvider.notifier).checkConnectivity();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                connectivity.friendlyMessage.isNotEmpty
                    ? connectivity.friendlyMessage
                    : (isOnline
                        ? 'Perangkat kasir terhubung secara online'
                        : 'Koneksi kasir offline'),
                style: const TextStyle(fontFamily: 'Open Sans'),
              ),
              backgroundColor: dotColor,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 29,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                labelText,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 11 : 12,
                  color: dotColor,
                  letterSpacing: 0,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutletSelector(BuildContext context, WidgetRef ref) {
    final accessibleOutlets = ref.read(accessibleOutletsProvider);
    final currentSelected = ref.read(selectedOutletProvider);

    if (accessibleOutlets.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Cabang / Outlet',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Katalog produk dan transaksi POS akan otomatis disesuaikan dengan cabang yang dipilih.',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accessibleOutlets.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final outlet = accessibleOutlets[index];
                      final isSelected = outlet.id == currentSelected?.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5247A1)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          outlet.name,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                            color: isSelected
                                ? const Color(0xFF5247A1)
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        subtitle: Text(
                          outlet.address ?? 'Kode: ${outlet.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF5247A1),
                                size: 22,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!isSelected) {
                            switchActiveOutlet(ref, outlet);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Beralih ke ${outlet.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF5247A1),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
