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

    final selectedOutlet = ref.watch(selectedOutletProvider);
    final accessibleOutlets = ref.watch(accessibleOutletsProvider);
    final outletName = selectedOutlet?.name.isNotEmpty == true
        ? selectedOutlet!.name
        : 'Kopi Kato - Cabang Sudirman';
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

                // Badge Toko / Outlet (Reaktif terhadap selectedOutletProvider)
                Flexible(
                  child: InkWell(
                    onTap: hasMultipleOutlets
                        ? () => _showOutletSelector(context, ref)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                          Flexible(
                            child: Text(
                              outletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF5247A1),
                                letterSpacing: 0,
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (hasMultipleOutlets) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF5247A1),
                            ),
                          ],
                        ],
                      ),
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. User Avatar & Nama Pengguna (Samantha Putri) - Tampilan statis profil kasir tanpa popup menu
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Kotak Ikon User: 30x30, background putih, radius 8px
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/Icons_SVG/icon_user.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF5247A1),
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Color(0xFF5247A1),
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
                          color: Colors.white,
                          letterSpacing: 0,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
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
