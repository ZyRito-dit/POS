import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';

/// Modal dialog / bottom sheet notifikasi terintegrasi dengan `/api/v1/notifications`.
/// Menampilkan daftar notifikasi real-time, badge unread, dan aksi tandai dibaca.
class KatoNotificationsModal extends ConsumerStatefulWidget {
  final bool isBottomSheet;

  const KatoNotificationsModal({
    super.key,
    this.isBottomSheet = false,
  });

  /// Membuka modal notifikasi secara responsif:
  /// - Di layar Tablet / Desktop (lebar >= 600px): Ditampilkan sebagai Dialog melayang.
  /// - Di layar Mobile Phone (< 600px): Ditampilkan sebagai Modal Bottom Sheet.
  static Future<void> show(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (ctx) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: KatoNotificationsModal(isBottomSheet: false),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const KatoNotificationsModal(isBottomSheet: true),
      );
    }
  }

  @override
  ConsumerState<KatoNotificationsModal> createState() =>
      _KatoNotificationsModalState();
}

class _KatoNotificationsModalState
    extends ConsumerState<KatoNotificationsModal> {
  // 0: Semua, 1: Belum Dibaca
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isLoading = ref.watch(isNotificationsLoadingProvider);

    final filteredNotifications = _filterIndex == 1
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;

    final content = Container(
      width: widget.isBottomSheet ? double.infinity : 500,
      constraints: BoxConstraints(
        maxHeight: widget.isBottomSheet
            ? MediaQuery.sizeOf(context).height * 0.85
            : 580,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar jika dalam mode Bottom Sheet
          if (widget.isBottomSheet)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // ---------------------------------------------------------------
          // 1. Header Notifikasi (Icon, Judul, Badge, & Tombol Tutup)
          // ---------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F0FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF5247A1),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount Baru',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                // Tombol Tutup (X)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF6B7280),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------------
          // 2. Filter Tabs & Tombol "Tandai Semua Dibaca"
          // ---------------------------------------------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua (${notifications.length})',
                  isSelected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Belum Dibaca ($unreadCount)',
                  isSelected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    key: const Key('mark_all_read_button'),
                    onTap: () => ref
                        .read(notificationsProvider.notifier)
                        .markAllAsRead(),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 15,
                            color: Color(0xFF5247A1),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tandai Dibaca',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF5247A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          // ---------------------------------------------------------------
          // 3. Daftar Notifikasi
          // ---------------------------------------------------------------
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF5247A1),
              onRefresh: () => ref
                  .read(notificationsProvider.notifier)
                  .fetchNotifications(),
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState(isLoading)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filteredNotifications[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return SafeArea(child: content);
    }
    return content;
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5247A1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5247A1),
          strokeWidth: 2.5,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _filterIndex == 1
                  ? 'Semua Notifikasi Telah Dibaca'
                  : 'Belum Ada Notifikasi',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pemberitahuan transaksi pembayaran, status kasir, dan info sistem akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(SystemNotification item) {
    final iconData = _getNotificationIcon(item);
    final iconColor = _getNotificationColor(item);
    final iconBgColor = iconColor.withValues(alpha: 0.12);

    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFFAF9FF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (!item.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFDEDBF5),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon Tipe Notifikasi
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),

              // Detail Notifikasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5247A1),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.formatNotificationDateTime(item.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(SystemNotification item) {
    switch (item.severity) {
      case NotificationSeverity.success:
        return Icons.check_circle_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.error:
        return Icons.cancel_outlined;
      case NotificationSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _getNotificationColor(SystemNotification item) {
    switch (item.severity) {
      case NotificationSeverity.success:
        return const Color(0xFF10B981);
      case NotificationSeverity.warning:
        return const Color(0xFFF59E0B);
      case NotificationSeverity.error:
        return const Color(0xFFEF4444);
      case NotificationSeverity.info:
        return const Color(0xFF5247A1);
    }
  }
}
