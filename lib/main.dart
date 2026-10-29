import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';

/// Konfigurasi Emulator Layar (DevicePreview):
/// - Set ke `false` untuk MEMATIKAN emulator (tampilan layar penuh biasa).
/// - Set ke `true` untuk MENGAKTIFKAN emulator (bisa pilih HP, Tablet, iOS, Android).
const bool kEnableDevicePreview = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Support both portrait (HP/Mobile) and landscape (Tablet/POS Desktop) on Android & iOS
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    DevicePreview(
      enabled: kEnableDevicePreview,
      builder: (context) => const ProviderScope(child: NexSellApp()),
    ),
  );
}

class NexSellApp extends ConsumerWidget {
  const NexSellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? AppPalette.dark.surface1
            : AppPalette.light.surface1,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'NexSell POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
