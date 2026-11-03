import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global ThemeMode provider - defaults to Light Mode (Mode Putih Utama).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Adaptive color palette for Light Mode (Primary) and Dark Mode.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color canvas;
  final Color surface1;
  final Color surface2;
  final Color surfaceHover;
  final Color accent;
  final Color accentHover;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;

  const AppPalette({
    required this.canvas,
    required this.surface1,
    required this.surface2,
    required this.surfaceHover,
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
  });

  /// Primary Light Mode Palette (Clean White & NexSell Royal Purple-Indigo)
  static const AppPalette light = AppPalette(
    canvas: Color(0xFFF8F9FA),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF6F7F9),
    surfaceHover: Color(0xFFE5E7EB),
    accent: Color(0xFF5247A1),
    accentHover: Color(0xFF43388A),
    accentSoft: Color(0xFFF1F0FA),
    success: Color(0xFF28A555),
    successSoft: Color(0x0D28A555),
    warning: Color(0xFFD97706),
    warningSoft: Color(0xFFFEF3C7),
    error: Color(0xFFDC2626),
    errorSoft: Color(0xFFFEE2E2),
    textPrimary: Color(0xFF1E1E1E),
    textSecondary: Color(0xFF565656),
    textMuted: Color(0xFF808080),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
  );

  /// Secondary Dark Mode Palette (Deep Slate & Vibrant Violet-Indigo)
  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF0D1117),
    surface1: Color(0xFF161B22),
    surface2: Color(0xFF21262D),
    surfaceHover: Color(0xFF30363D),
    accent: Color(0xFF7C3AED),
    accentHover: Color(0xFF6D28D9),
    accentSoft: Color(0x2E7C3AED),
    success: Color(0xFF2EA043),
    successSoft: Color(0x262EA043),
    warning: Color(0xFFD29922),
    warningSoft: Color(0x26D29922),
    error: Color(0xFFF85149),
    errorSoft: Color(0x26F85149),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF6E7681),
    border: Color(0xFF30363D),
    borderStrong: Color(0xFF484F58),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface1,
    Color? surface2,
    Color? surfaceHover,
    Color? accent,
    Color? accentHover,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Design token system for NexSell POS.
class AppTheme {
  AppTheme._();

  // Static fallback tokens for legacy references
  static const Color canvas = Color(0xFFF4F6FA);
  static const Color surface1 = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEEF2F6);
  static const Color surfaceHover = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFF6D28D9);
  static const Color accentHover = Color(0xFF5B21B6);
  static const Color accentSoft = Color(0xFFEDE9FE);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // --- Radius Tokens ---
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 22.0;

  // --- Spacing Scale (4px grid) ---
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        palette: AppPalette.light,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        palette: AppPalette.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: palette.canvas,
      extensions: <ThemeExtension<dynamic>>[palette],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.accent,
        onPrimary: Colors.white,
        secondary: palette.accent,
        onSecondary: Colors.white,
        error: palette.error,
        onError: Colors.white,
        surface: palette.surface1,
        onSurface: palette.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Open Sans',
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface1,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface2,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13.5),
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: 13,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.surface2,
          disabledForegroundColor: palette.textMuted,
          // Safe bounded minimumSize so buttons inside Row/Wrap never crash with infinite width
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: space16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: space16),
          side: BorderSide(color: palette.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
      ),
    );
  }
}
