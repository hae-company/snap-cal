import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CalorieProgress extends StatelessWidget {
  final int current;
  final int goal;

  const CalorieProgress({super.key, required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.5) : 0.0;
    final over = current > goal;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$current kcal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: over ? AppColors.danger : AppColors.primary)),
            Text('/ $goal', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.divider,
            color: over ? AppColors.danger : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            over ? '${current - goal} kcal 초과' : '${goal - current} kcal 남음',
            style: TextStyle(fontSize: 12, color: over ? AppColors.danger : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
