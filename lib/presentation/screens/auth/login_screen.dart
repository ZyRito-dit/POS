import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';

/// Halaman Login Kato POS sesuai desain Figma dan referensi gambar.
/// Responsif untuk layar HP (Mobile), Tablet, maupun Desktop dengan:
/// 1. Shape kanan dan kiri yang saling dempet & tumpang tindih (overlapping).
/// 2. Jarak hak cipta (footer) yang proporsional ke bawah layar.
/// 3. Form input dengan kotak ikon terpisah dan border terpadu sesuai gambar.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ref
          .read(loginProvider.notifier)
          .setFailure('Silakan masukkan email Anda');
      return;
    }

    if (password.isEmpty) {
      ref
          .read(loginProvider.notifier)
          .setFailure('Silakan masukkan kata sandi Anda');
      return;
    }

    await ref.read(loginProvider.notifier).login(
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginProvider, (_, next) {
      if (next is LoginSuccess && context.mounted) {
        context.go(AppRoutes.home);
      }
    });

    final loginState = ref.watch(loginProvider);
    final isLoading = loginState is LoginLoading;
    final errorMessage =
        loginState is LoginFailure ? loginState.message : null;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Perhitungan posisi & ukuran shape responsif (HP, Tablet Small/Medium/Large, Desktop)
    // Menjamin bentuk Kanan dan Kiri PASTI saling dempet & tumpang tindih di belakang kartu.
    final double shapeKananWidth;
    final double shapeKananHeight;
    final double shapeKananLeft;
    final double shapeKananTop;

    final double shapeKiriWidth;
    final double shapeKiriHeight;
    final double shapeKiriLeft;
    final double shapeKiriBottom;

    if (isMobile) {
      // Tampilan HP: Bentuk proporsional membingkai layar vertikal
      final skSize = (screenHeight * 0.58).clamp(420.0, 520.0);
      shapeKananWidth = skSize;
      shapeKananHeight = skSize;
      shapeKananLeft = screenWidth - (skSize * 0.72);
      shapeKananTop = -skSize * 0.05;

      final slSize = (screenHeight * 0.38).clamp(260.0, 360.0);
      shapeKiriWidth = slSize;
      shapeKiriHeight = slSize;
      shapeKiriLeft = -slSize * 0.15;
      shapeKiriBottom = 0.0;
    } else {
      // Tampilan Tablet (Small, Medium, Large) & Desktop (Landscape & Portrait)
      // Skala dihitung dinamis dari dimensi layar agar kurva terhubung menyatu
      final skSize = math.max(screenHeight * 1.05, screenWidth * 0.72);
      shapeKananWidth = skSize;
      shapeKananHeight = skSize;
      shapeKananLeft = screenWidth - skSize; // Tersemat di kanan atas membentang ke tengah
      shapeKananTop = 0.0;

      final slSize = math.max(screenHeight * 0.58, screenWidth * 0.38);
      shapeKiriWidth = slSize;
      shapeKiriHeight = slSize;
      shapeKiriLeft = 0.0;                   // Tersemat di kiri bawah
      shapeKiriBottom = 0.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF5247A1), // Background utama #5247A1
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // -------------------------------------------------------------------
          // Shape Kanan (Top-Right melengkung ke bawah tengah)
          // -------------------------------------------------------------------
          Positioned(
            left: shapeKananLeft,
            top: shapeKananTop,
            width: shapeKananWidth,
            height: shapeKananHeight,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Shape Kanan Atas.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/shape_kanan_atas.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/Image/Shape Kanan Atas.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Shape Kiri (Bottom-Left melengkung ke atas tengah)
          // Tumpang tindih dengan Shape Kanan di sisi kiri bawah kartu
          // -------------------------------------------------------------------
          Positioned(
            left: shapeKiriLeft,
            bottom: shapeKiriBottom,
            width: shapeKiriWidth,
            height: shapeKiriHeight,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Shape Kiri Bawah.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/shape_kiri_bawah.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/Image/Shape Kiri Bawah.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Foreground Content (Responsif & Anti-Overflow dengan Scroll)
          // -------------------------------------------------------------------
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24, // Jarak kanan dan kiri 24px
                        vertical: isMobile ? 24 : 36,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Text Paling Atas (Title)
                            _buildTopHeader(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),

                            SizedBox(height: isMobile ? 24 : 36),

                            // 2. Card Content (Kartu Putih Login)
                            _buildCardContent(
                              isMobile: isMobile,
                              isLoading: isLoading,
                              errorMessage: errorMessage,
                            ),
                          ],
                        ),
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

  /// Bagian Header Teks Paling Atas
  Widget _buildTopHeader({required bool isMobile, required bool isTablet}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 779),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Selamat datang di Kato POS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 26 : (isTablet ? 34 : 42),
            color: const Color(0xFFFFFFFF),
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  /// Bagian Kotak Kartu Putih (Card Content)
  Widget _buildCardContent({
    required bool isMobile,
    required bool isLoading,
    required String? errorMessage,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isMobile ? 420 : 500),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // #0000000D
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 36,
        vertical: isMobile ? 28 : 36,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Logo (50 x 50)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/Logo/logo_kato_pos.png',
                width: isMobile ? 48 : 54,
                height: isMobile ? 48 : 54,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: isMobile ? 48 : 54,
                  height: isMobile ? 48 : 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5247A1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title Logo: "Kato POS"
            const Text(
              'Kato POS',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF5247A1),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),

            // Sub-title: "Masuk ke akun Anda"
            const Text(
              'Masuk ke akun Anda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1E1E1E),
                letterSpacing: 0,
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Input 1: Email
            _buildInputField(
              label: 'Email',
              controller: _emailController,
              hintText: 'Masukkan email',
              iconSvgPath: 'assets/Icons_SVG/mail.svg',
              altSvgPath: 'assets/Icons_SVG/mail.svg',
              fallbackIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20),

            // Input 2: Kata sandi
            _buildInputField(
              label: 'Kata sandi',
              controller: _passwordController,
              hintText: 'Masukkan kata sandi',
              iconSvgPath: 'assets/Icons_SVG/lock.svg',
              altSvgPath: 'assets/Icons_SVG/lock.svg',
              fallbackIcon: Icons.lock_outline_rounded,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 30),

            // Tombol "Masuk"
            SizedBox(
              width: double.infinity,
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF5247A1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000), // #0000001A
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFFFFFFFF),
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Text Tombol "Lupa kata sandi?"
            InkWell(
              onTap: () => context.push(AppRoutes.forgotPassword),
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox(
                width: 116,
                height: 24,
                child: Center(
                  child: Text(
                    'Lupa kata sandi?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF5247A1),
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Komponen Input Field sesuai format gambar referensi:
  /// Kontainer tunggal terpadu 10px rounded, kotak ikon abu-abu #FAFAFA di sisi kiri,
  /// pembatas vertikal 1px rapi, teks input presisi terpusat, dan ikon mata outline di ujung kanan.
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String iconSvgPath,
    required String altSvgPath,
    required IconData fallbackIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    const borderColor = Color(0x1A000000); // 1px solid #0000001A

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Text (14px, #1E1E1E)
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF1E1E1E),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),

        // Kontainer Input Terpadu
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kotak Ikon di Kiri (41 x 42, background #FAFAFA, divider kanan)
              Container(
                width: 41,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                  border: Border(
                    right: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconSvgPath,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF808080),
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) =>
                      SvgPicture.asset(
                    altSvgPath,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF808080),
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (context, error, stackTrace) => Icon(
                      fallbackIcon,
                      size: 18,
                      color: const Color(0xFF808080),
                    ),
                  ),
                ),
              ),

              // Area Input Teks Terpusat Vertikal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextFormField(
                      controller: controller,
                      obscureText: isPassword ? obscureText : false,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      onFieldSubmitted: onSubmitted,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF808080),
                          letterSpacing: 0,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),

              // Ikon Mata Outline untuk Toggle Password
              if (isPassword)
                GestureDetector(
                  onTap: onToggleObscure,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(right: 14, left: 6),
                    alignment: Alignment.center,
                    child: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFF808080),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
