import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../core/nutrition_calc.dart';

/// 탄·단·지 세 칸 요약 (현재 / 목표 + 얇은 막대)
class MacroSummary extends StatelessWidget {
  const MacroSummary({
    super.key,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.goals,
  });

  final int carbs;
  final int protein;
  final int fat;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: MacroColumn(
            label: '탄수화물',
            value: carbs,
            goal: goals.carbsG,
            color: p.carbs,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: MacroColumn(
            label: '단백질',
            value: protein,
            goal: goals.proteinG,
            color: p.protein,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: MacroColumn(
            label: '지방',
            value: fat,
            goal: goals.fatG,
            color: p.fat,
          ),
        ),
      ],
    );
  }
}

class MacroColumn extends StatelessWidget {
  const MacroColumn({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final over = goal > 0 && value > goal;
    return Semantics(
      label: '$label $value그램, 목표 $goal그램',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: p.text2)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: AppText.numeric(
                    AppText.headline,
                  ).copyWith(color: over ? p.over : p.text1),
                ),
                TextSpan(
                  text: ' / ${goal}g',
                  style: AppText.numeric(
                    AppText.micro,
                  ).copyWith(color: p.text3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0,
            ),
            duration: AppMotion.ring,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: p.surfaceAlt,
                color: over ? p.over : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
