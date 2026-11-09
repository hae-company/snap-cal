import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 먹은 칼로리 / 목표 막대
class CalorieProgress extends StatelessWidget {
  const CalorieProgress({super.key, required this.current, required this.goal});

  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final over = current > goal;
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final accent = over ? p.over : p.brand;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$current',
              style: AppText.title1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accent,
                fontFeatures: AppText.display.fontFeatures,
              ),
            ),
            const SizedBox(width: AppSpace.xxs),
            Text('kcal', style: AppText.caption.copyWith(color: accent)),
            const Spacer(),
            Text('/ $goal', style: AppText.body.copyWith(color: p.text2)),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: p.surfaceAlt,
            color: accent,
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            over ? '${current - goal} kcal 초과' : '${goal - current} kcal 남음',
            style: AppText.caption.copyWith(color: over ? p.over : p.text2),
          ),
        ),
      ],
    );
  }
}
