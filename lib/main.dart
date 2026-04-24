import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:royal_app/core/providers/locale_provider.dart';
import 'package:royal_app/core/router/app_router.dart';
import 'package:royal_app/core/services/background_location_service.dart';
import 'package:royal_app/core/services/hive_service.dart';
import 'package:royal_app/core/theme/app_theme.dart';
import 'package:royal_app/core/theme/theme_provider.dart';
import 'package:royal_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await HiveService.instance.init();
  try {
    await BackgroundLocationService.instance.init();
  } catch (_) {
    // Background location not supported on this device/simulator — safe to ignore.
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: MotoStackApp()),
    ),
  );
}

class MotoStackApp extends ConsumerWidget {
  const MotoStackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final locale    = ref.watch(localeNotifierProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp.router(
        title: 'MotoStack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        routerConfig: appRouter,
      ),
    );
  }
}
