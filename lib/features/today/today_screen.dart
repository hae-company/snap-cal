import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/macro_summary.dart';
import '../../shared/widgets/meal_section.dart';

/// 홈. "지금 얼마나 남았지?"에 바로 답한다.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final now = DateTime.now();
    final goals = ref.watch(goalsProvider);
    final records =
        ref.watch(mealsByDateProvider(dateKey(now))).value ?? const [];
    final streak = ref.watch(streakProvider).value ?? 0;

    final eaten = records.fold(0, (s, r) => s + r.calories);
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          120,
        ),
        children: [
          Row(
            children: [
              const LogoTile(size: 36),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('M월 d일 EEEE', 'ko').format(now),
                      style: AppText.caption.copyWith(color: p.text2),
                    ),
                    Text(
                      _greeting(now),
                      style: AppText.title2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (streak > 0) _StreakChip(days: streak),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.xl,
                AppSpace.lg,
                AppSpace.lg,
              ),
              child: Column(
                children: [
                  CalorieRing(eaten: eaten, goal: goals.kcal),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat(label: '먹은 양', value: formatKcal(eaten)),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xl,
                        ),
                        color: p.border,
                      ),
                      _Stat(label: '목표', value: formatKcal(goals.kcal)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Divider(color: p.border),
                  const SizedBox(height: AppSpace.md),
                  MacroSummary(
                    carbs: carbs,
                    protein: protein,
                    fat: fat,
                    goals: goals,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text('오늘의 식사', style: AppText.title2.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpace.sm),
          for (final type in MealType.all) ...[
            MealSection(
              mealType: type,
              records: records.where((r) => r.mealType == type).toList(),
              onDelete: (r) => ref.read(mealActionsProvider).delete(r.id!),
              onAdd: () => context.push('${Routes.capture}?meal=$type'),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }

  static String _greeting(DateTime now) => switch (now.hour) {
    < 5 => '늦은 밤이에요',
    < 11 => '좋은 아침이에요',
    < 17 => '오늘도 가볍게',
    _ => '오늘 하루 수고했어요',
  };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(label, style: AppText.caption.copyWith(color: p.text2)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value, style: AppText.numeric(AppText.headline)),
              TextSpan(
                text: ' kcal',
                style: AppText.micro.copyWith(color: p.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: p.warning),
          const SizedBox(width: 2),
          Text(
            '$days일 연속',
            style: AppText.micro.copyWith(fontSize: 12, color: p.warning),
          ),
        ],
      ),
    );
  }
}
