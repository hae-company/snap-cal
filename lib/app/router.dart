import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/meal_type.dart';
import '../data/billing/billing_models.dart';
import '../data/providers.dart';
import '../features/capture/camera_screen.dart';
import '../features/capture/result_screen.dart';
import '../features/food_entry/add_food_screen.dart';
import '../features/log/calendar_screen.dart';
import '../features/my/my_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/report/report_screen.dart';
import '../features/today/today_screen.dart';
import 'theme/tokens.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const log = '/log';
  static const report = '/report';
  static const my = '/my';

  /// 전체 화면 촬영. `?meal=lunch`로 끼니를 미리 고를 수 있다.
  static const capture = '/capture';
  static const result = '/result';

  /// 검색·직접 입력으로 기록. `?meal=lunch&date=2026-11-09&photo=/path.jpg`
  static const add = '/add';

  /// 프리미엄 구독. `?source=limit&feature=csvExport`
  static const paywall = '/paywall';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 온보딩을 마치면 redirect를 다시 계산하게 한다.
  final onboarded = ValueNotifier<bool>(ref.read(onboardedProvider));
  ref.listen(onboardedProvider, (_, v) => onboarded.value = v);

  final router = GoRouter(
    initialLocation: Routes.today,
    refreshListenable: onboarded,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // 온보딩 마지막에 페이월을 띄우므로 페이월은 온보딩 전에도 허용한다
      final allowedBeforeOnboarding =
          atOnboarding || state.matchedLocation == Routes.paywall;
      if (!onboarded.value) {
        return allowedBeforeOnboarding ? null : Routes.onboarding;
      }
      if (atOnboarding) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.capture,
        pageBuilder: (_, state) {
          final meal = state.uri.queryParameters['meal'];
          final date = state.uri.queryParameters['date'];
          return MaterialPage(
            fullscreenDialog: true,
            child: CameraScreen(
              presetMeal: MealType.all.contains(meal) ? meal : null,
              date: date != null && DateTime.tryParse(date) != null
                  ? date
                  : null,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.add,
        pageBuilder: (_, state) {
          final q = state.uri.queryParameters;
          final meal = q['meal'];
          final date = q['date'];
          return MaterialPage(
            fullscreenDialog: true,
            child: AddFoodScreen(
              presetMeal: MealType.all.contains(meal) ? meal : null,
              date: date != null && DateTime.tryParse(date) != null
                  ? date
                  : null,
              photoPath: q['photo'],
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.paywall,
        pageBuilder: (_, state) {
          final q = state.uri.queryParameters;
          return MaterialPage(
            fullscreenDialog: true,
            child: PaywallScreen(
              source:
                  PaywallSource.values.asNameMap()[q['source']] ??
                  PaywallSource.my,
              feature: PremiumFeature.values.asNameMap()[q['feature']],
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.result,
        redirect: (_, state) => state.extra is ResultArgs ? null : Routes.today,
        builder: (_, state) => ResultScreen(args: state.extra! as ResultArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          for (final (path, screen) in [
            (Routes.today, const TodayScreen()),
            (Routes.log, const CalendarScreen()),
            (Routes.report, const ReportScreen()),
            (Routes.my, const MyScreen()),
          ])
            StatefulShellBranch(
              routes: [GoRoute(path: path, builder: (_, _) => screen)],
            ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    onboarded.dispose();
  });
  return router;
});

/// 하단 탭: 오늘 / 기록 / (촬영 버튼) / 리포트 / MY
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_rounded, Icons.home_outlined, '오늘'),
    (Icons.calendar_month_rounded, Icons.calendar_month_outlined, '기록'),
    (Icons.insights_rounded, Icons.insights_outlined, '리포트'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'MY'),
  ];

  void _go(int i) {
    HapticFeedback.selectionClick();
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget tab(int i) {
      final (on, off, label) = _tabs[i];
      final selected = shell.currentIndex == i;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => _go(i),
            radius: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? on : off,
                  size: 24,
                  color: selected ? p.text1 : p.text3,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppText.micro.copyWith(
                    color: selected ? p.text1 : p.text3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: shell,
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                tab(0),
                tab(1),
                const Expanded(child: Center(child: CaptureButton())),
                tab(2),
                tab(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 가운데 촬영 버튼
class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '음식 촬영',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push(Routes.capture);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppBrand.gradient,
            boxShadow: [
              BoxShadow(
                color: AppBrand.orange.withAlpha(90),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
