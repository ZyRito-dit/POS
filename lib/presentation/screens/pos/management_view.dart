import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/data/dummy/pos_dummy_data.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/app_text_field.dart';
import 'package:pos_apps_umkm/presentation/widgets/primary_button.dart';

class ManagementView extends ConsumerWidget {
  const ManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final staffUsers = ref.watch(staffUsersProvider);
    final terminal = PosDummyData.terminalInfo;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? AppTheme.space16 : AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 0: Theme & Display Preference Card (Mode Putih Utama & Mode Gelap)
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTheme.space16,
              runSpacing: AppTheme.space12,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTheme.space12,
                  runSpacing: AppTheme.space8,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: palette.accent,
                        size: 22,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema Tampilan Aplikasi',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark
                                ? 'Mode Gelap aktif'
                                : 'Mode Putih (Utama) aktif',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppTheme.space8,
                  children: [
                    ChoiceChip(
                      label: const Text('Mode Putih (Utama)'),
                      selected: !isDark,
                      onSelected: (_) {
                        ref.read(themeModeProvider.notifier).state =
                            ThemeMode.light;
                      },
                      selectedColor: palette.accent,
                      backgroundColor: palette.surface2,
                      labelStyle: TextStyle(
                        color: !isDark ? Colors.white : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Mode Gelap'),
                      selected: isDark,
                      onSelected: (_) {
                        ref.read(themeModeProvider.notifier).state =
                            ThemeMode.dark;
                      },
                      selectedColor: palette.accent,
                      backgroundColor: palette.surface2,
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Section 1: Terminal Status Card (Bab 4.2.2 & Bab 7)
          Text(
            'Status Terminal Kasir dan Perangkat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Konfigurasi perangkat kasir, konektivitas payment gateway QRIS, dan sinkronisasi data.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTheme.space16,
                  runSpacing: AppTheme.space12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(
                            Icons.point_of_sale_rounded,
                            color: palette.accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${terminal.name} (${terminal.machineCode})',
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space2),
                              Text(
                                terminal.locationName,
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .addNotification(
                              title: 'Sinkronisasi Data Selesai',
                              message:
                                  'Katalog produk, stok, dan konfigurasi QRIS pada ${terminal.machineCode} telah diperbarui.',
                              severity: NotificationSeverity.info,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sinkronisasi katalog dan harga berhasil dijalankan.',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                            backgroundColor: palette.surface1,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sinkronisasi Katalog'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                Divider(height: 1, color: palette.border),
                const SizedBox(height: AppTheme.space16),
                Wrap(
                  spacing: AppTheme.space24,
                  runSpacing: AppTheme.space12,
                  children: [
                    _TerminalSpecItem(
                      label: 'Status Terminal',
                      value: 'Aktif (Online)',
                      valueColor: palette.success,
                    ),
                    _TerminalSpecItem(
                      label: 'Payment Gateway',
                      value: terminal.paymentGateway,
                    ),
                    _TerminalSpecItem(
                      label: 'Printer Kasir',
                      value: terminal.printerStatus,
                    ),
                    _TerminalSpecItem(
                      label: 'Mode API',
                      value: 'Simulasi Lokal (Dummy Data)',
                      valueColor: palette.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Section 2: System Notifications (Bab 4.2.5 /api/v1/notifications)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space4,
                children: [
                  Text(
                    'Notifikasi Sistem',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.errorSoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '$unreadCount belum dibaca',
                        style: TextStyle(
                          color: palette.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).markAllAsRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Tandai Semua Dibaca'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: palette.border),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationRow(item: item);
              },
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // Section 3: RBAC Staff & User Management (Bab 4.1 & FAQ Q3/Q6)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Pengguna dan Hak Akses (RBAC)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      'Kelola akun kasir, operator, manajer toko, dan teknisi.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddUserSheet(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Tambah Pengguna'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffUsers.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: palette.border),
              itemBuilder: (context, index) {
                final u = staffUsers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: palette.accent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    u.displayName,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${u.username} • ${u.email ?? "-"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      u.role ?? 'staff',
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final palette = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => const _AddStaffUserSheet(),
    );
  }
}

class _TerminalSpecItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TerminalSpecItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? palette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  final SystemNotification item;

  const _NotificationRow({required this.item});

  IconData get _icon {
    switch (item.severity) {
      case NotificationSeverity.error:
        return Icons.error_outline_rounded;
      case NotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.success:
        return Icons.check_circle_outline_rounded;
      case NotificationSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _color(AppPalette palette) {
    switch (item.severity) {
      case NotificationSeverity.error:
        return palette.error;
      case NotificationSeverity.warning:
        return palette.warning;
      case NotificationSeverity.success:
        return palette.success;
      case NotificationSeverity.info:
        return palette.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final color = _color(palette);

    return InkWell(
      onTap: () =>
          ref.read(notificationsProvider.notifier).markAsRead(item.id),
      child: Container(
        color: item.isRead
            ? Colors.transparent
            : palette.accent.withValues(alpha: 0.05),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(_icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        AppFormatters.formatTimeOnly(item.createdAt),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    item.message,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStaffUserSheet extends ConsumerStatefulWidget {
  const _AddStaffUserSheet();

  @override
  ConsumerState<_AddStaffUserSheet> createState() => _AddStaffUserSheetState();
}

class _AddStaffUserSheetState extends ConsumerState<_AddStaffUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'operator';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(registerProvider.notifier).register(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          email: _emailCtrl.text.trim(),
          fullName: _fullNameCtrl.text.trim(),
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    ref.listen<RegisterState>(registerProvider, (_, next) {
      if (next is RegisterSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun "${next.user.username}" (${next.user.role}) berhasil ditambahkan.',
              style: TextStyle(color: palette.textPrimary),
            ),
            backgroundColor: palette.surface1,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(registerProvider.notifier).reset();
      }
    });

    final state = ref.watch(registerProvider);
    final isLoading = state is RegisterLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space24,
        right: AppTheme.space24,
        top: AppTheme.space24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space32,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Text(
                'Tambah Pengguna Baru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                'Buat akun kasir, operator, atau teknisi dengan Role-Based Access Control (RBAC).',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppTheme.space20),
              AppTextField(
                controller: _fullNameCtrl,
                label: 'Nama Lengkap',
                hint: 'Misal: Dewi Lestari',
                prefixIconData: Icons.badge_outlined,
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'kasir02@nexsell.id',
                prefixIconData: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Username wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'kasir02@nexsell.id',
                prefixIconData: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Email wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                'Peran Pengguna (Role RBAC)',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                dropdownColor: palette.surface1,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'operator',
                    child: Text('Operator / Kasir Utama'),
                  ),
                  DropdownMenuItem(
                    value: 'staff',
                    child: Text('Staff Kasir'),
                  ),
                  DropdownMenuItem(
                    value: 'tenant-admin',
                    child: Text('Tenant Admin / Manajer Toko'),
                  ),
                  DropdownMenuItem(
                    value: 'technician',
                    child: Text('Teknisi Perangkat'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Minimal 6 karakter',
                prefixIconData: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: palette.textMuted,
                    size: 20,
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Password wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppTheme.space24),
              PrimaryButton(
                label: 'Simpan Akun Pengguna',
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
