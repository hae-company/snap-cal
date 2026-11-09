import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/capture/camera_screen.dart';
import '../features/capture/result_screen.dart';
import '../features/log/calendar_screen.dart';
import '../features/my/settings_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/report/stats_screen.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const calendar = '/calendar';
  static const stats = '/stats';
  static const capture = '/capture';
  static const settings = '/settings';
  static const result = '/result';
}

final routerProvider = Provider<GoRouter>((ref) {
  // 온보딩을 마치면 redirect를 다시 계산하게 한다.
  final onboarded = ValueNotifier<bool>(ref.read(onboardedProvider));
  ref.listen(onboardedProvider, (_, v) => onboarded.value = v);

  final router = GoRouter(
    initialLocation: Routes.calendar,
    refreshListenable: onboarded,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded.value) return atOnboarding ? null : Routes.onboarding;
      if (atOnboarding) return Routes.calendar;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.result,
        redirect: (_, state) =>
            state.extra is ResultArgs ? null : Routes.capture,
        builder: (_, state) => ResultScreen(args: state.extra! as ResultArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (_, _) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stats,
                builder: (_, _) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.capture,
                builder: (_, _) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
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

/// 하단 탭. 4단계에서 오늘 / 기록 / 촬영 버튼 / 리포트 / MY 구조로 바꾼다.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '캘린더'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '통계'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: '촬영'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
