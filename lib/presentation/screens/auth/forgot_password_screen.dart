import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';

/// Halaman Informasi Lupa Kata Sandi sesuai referensi desain Kato POS.
/// Menampilkan panduan bagi kasir/karyawan untuk menghubungi Admin atau Owner
/// outlet guna melihat atau mengatur ulang kata sandi akun.
/// Responsif untuk semua perangkat tablet dan smartphone (HP).
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Breakpoints responsif
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Penataan proporsional aset Shape latar belakang
    final double shapeKananWidth;
    final double shapeKananHeight;
    final double shapeKananLeft;
    final double shapeKananTop;

    final double shapeKiriWidth;
    final double shapeKiriHeight;
    final double shapeKiriLeft;
    final double shapeKiriBottom;

    if (isMobile) {
      final skSize = math.max(screenHeight * 0.70, screenWidth * 1.05);
      shapeKananWidth = skSize;
      shapeKananHeight = skSize;
      shapeKananLeft = screenWidth - (skSize * 0.75);
      shapeKananTop = -skSize * 0.12;

      final slSize = math.max(screenHeight * 0.45, screenWidth * 0.75);
      shapeKiriWidth = slSize;
      shapeKiriHeight = slSize;
      shapeKiriLeft = -slSize * 0.15;
      shapeKiriBottom = 0.0;
    } else {
      final skSize = math.max(screenHeight * 1.05, screenWidth * 0.72);
      shapeKananWidth = skSize;
      shapeKananHeight = skSize;
      shapeKananLeft = screenWidth - skSize;
      shapeKananTop = 0.0;

      final slSize = math.max(screenHeight * 0.58, screenWidth * 0.38);
      shapeKiriWidth = slSize;
      shapeKiriHeight = slSize;
      shapeKiriLeft = 0.0;
      shapeKiriBottom = 0.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF5247A1),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // -------------------------------------------------------------------
          // Shape Kanan Atas
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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Shape Kiri Bawah
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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Konten Utama (Responsif & Anti-Overflow)
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
                        horizontal: 24,
                        vertical: isMobile ? 24 : 36,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Title Teks Paling Atas
                            _buildTopHeader(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),

                            SizedBox(height: isMobile ? 24 : 36),

                            // 2. Card Putih Lupa Kata Sandi
                            _buildCardContent(
                              context: context,
                              isMobile: isMobile,
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

  /// Bagian Kotak Kartu Putih (Card Content Lupa Kata Sandi)
  Widget _buildCardContent({
    required BuildContext context,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isMobile ? 420 : 480),
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
            color: Color(0x14000000), // #00000014
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

          const SizedBox(height: 18),

          // Judul Informasi: "Lupa Kata Sandi Anda?"
          const Text(
            'Lupa Kata Sandi Anda?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1E1E1E),
              letterSpacing: 0,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Penjelasan / Instruksi
          const Text(
            'Silakan hubungi Admin atau Owner outlet Anda untuk melihat atau mengatur ulang kata sandi akun ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF565656),
              letterSpacing: 0,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 26),

          // Tombol "Kembali Masuk"
          SizedBox(
            width: double.infinity,
            height: 44,
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
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text(
                  'Kembali Masuk',
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
        ],
      ),
    );
  }
}
