import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/app_text_field.dart';
import 'package:pos_apps_umkm/presentation/widgets/primary_button.dart';
import 'package:pos_apps_umkm/presentation/widgets/auth_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(registerProvider.notifier).register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;

    ref.listen<RegisterState>(registerProvider, (_, next) {
      if (next is RegisterSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun berhasil dibuat. Silakan login.',
              style: TextStyle(color: palette.textPrimary),
            ),
            backgroundColor: palette.surface1,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
        context.go(AppRoutes.login);
      }
    });

    final state = ref.watch(registerProvider);
    final isLoading = state is RegisterLoading;
    final errorMessage = state is RegisterFailure ? state.message : null;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.space48),
                _RegisterHeader(),
                const SizedBox(height: AppTheme.space32),
                AuthCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Buat Akun Baru',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Isi formulir di bawah untuk mendaftarkan akun.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: palette.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.space32),

                        if (errorMessage != null) ...[
                          _ErrorBanner(message: errorMessage),
                          const SizedBox(height: AppTheme.space20),
                        ],

                        AppTextField(
                          controller: _fullNameController,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap (opsional)',
                          prefixIconData: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: AppTheme.space16),

                        AppTextField(
                          controller: _usernameController,
                          label: 'Username',
                          hint: 'Masukkan username',
                          prefixIconData: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newUsername],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Username wajib diisi';
                            }
                            if (v.trim().length < 3) {
                              return 'Username minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space16),

                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Masukkan alamat email',
                          prefixIconData: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            final emailRegex =
                                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space16),

                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Minimal 8 karakter',
                          prefixIconData: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: palette.textMuted,
                              size: 20,
                            ),
                            tooltip: _obscurePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (v.length < 8) {
                              return 'Password minimal 8 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space16),

                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Konfirmasi Password',
                          hint: 'Ulangi password',
                          prefixIconData: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: palette.textMuted,
                              size: 20,
                            ),
                            tooltip: _obscureConfirm
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Konfirmasi password wajib diisi';
                            }
                            if (v != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space32),

                        PrimaryButton(
                          label: 'Daftar',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                        const SizedBox(height: AppTheme.space20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.login),
                              child: const Text('Masuk'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: palette.accent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person_add_outlined,
            color: palette.accent,
            size: 30,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        Text(
          'NexSell POS',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          'Daftarkan akun baru',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: palette.errorSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: palette.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: palette.error, size: 18),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: palette.error, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
