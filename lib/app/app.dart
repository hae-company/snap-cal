import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/billing/billing_providers.dart';
import '../data/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class CalorieSnapApp extends ConsumerWidget {
  const CalorieSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adsWarmupProvider);
    return MaterialApp.router(
      title: '칼로리스냅',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // 첫 화면에서 로고가 늦게 뜨지 않도록 미리 불러 둔다
        precacheImage(const AssetImage('assets/brand/tile.png'), context);
        return child!;
      },
    );
  }
}
