import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable background scaffold dengan template warna dan shape yang sama
/// persis dengan halaman Login dan Lupa Kata Sandi Kato POS.
class PaymentBackgroundScaffold extends StatelessWidget {
  final Widget child;

  const PaymentBackgroundScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isMobile = screenWidth < 600;

    // Perhitungan posisi responsif shape latar belakang
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
          // Foreground Content (Tengah Layar dengan Anti-Overflow Scroll)
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
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: screenHeight < 520
                              ? 12
                              : (isMobile ? 24 : 36),
                        ),
                        child: child,
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
}