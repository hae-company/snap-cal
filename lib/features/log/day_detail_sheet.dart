import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/providers.dart';
import '../../shared/widgets/calorie_progress.dart';
import '../../shared/widgets/meal_card.dart';
import '../../shared/widgets/nutrient_bar.dart';
import '../../shared/widgets/sheet_handle.dart';

Future<void> showDayDetailSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true, // 하단 탭 위로 띄운다
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scroll) =>
          DayDetailSheet(day: day, scrollController: scroll),
    ),
  );
}

/// 하루 기록 상세. 기록을 지우면 시트를 닫지 않고 바로 갱신된다.
class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({super.key, required this.day, this.scrollController});

  final DateTime day;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final goals = ref.watch(goalsProvider);
    final records =
        ref.watch(mealsByDateProvider(dateKey(day))).value ?? const [];

    final total = records.fold(0, (s, r) => s + r.calories);
    final carbs = records.fold(0, (s, r) => s + r.carbs);
    final protein = records.fold(0, (s, r) => s + r.protein);
    final fat = records.fold(0, (s, r) => s + r.fat);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.md,
          AppSpace.xxl,
        ),
        children: [
          const SheetHandle(),
          Text(
            DateFormat('M월 d일 EEEE', 'ko').format(day),
            style: AppText.headline.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          CalorieProgress(current: total, goal: goals.kcal),
          const SizedBox(height: AppSpace.md),
          if (records.isNotEmpty) ...[
            Card(
              color: p.bg,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('영양성분', style: AppText.label.copyWith(fontSize: 15)),
                    const SizedBox(height: 14),
                    NutrientBar(
                      label: '탄수화물',
                      value: carbs,
                      max: goals.carbsG,
                      color: p.carbs,
                      showRemaining: true,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    NutrientBar(
                      label: '단백질',
                      value: protein,
                      max: goals.proteinG,
                      color: p.protein,
                      showRemaining: true,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    NutrientBar(
                      label: '지방',
                      value: fat,
                      max: goals.fatG,
                      color: p.fat,
                      showRemaining: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          for (final type in MealType.all)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: MealCard(
                mealType: type,
                records: records.where((r) => r.mealType == type).toList(),
                onDelete: (id) => ref.read(mealActionsProvider).delete(id),
              ),
            ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
              child: Center(
                child: Text(
                  '이 날은 기록이 없어요',
                  style: AppText.body.copyWith(color: p.text3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
