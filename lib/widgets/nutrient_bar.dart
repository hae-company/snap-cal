import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NutrientBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String unit;
  final bool showRemaining;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
    this.showRemaining = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final over = value > max && max > 0;
    final remaining = max - value;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  color: over ? AppColors.danger : color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(
                '$value / $max$unit',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: over ? AppColors.danger : AppColors.textPrimary),
              ),
            ),
          ],
        ),
        if (showRemaining && max > 0)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                over ? '${-remaining}$unit 초과' : '${remaining}$unit 남음',
                style: TextStyle(fontSize: 10, color: over ? AppColors.danger : AppColors.textHint),
              ),
            ),
          ),
      ],
    );
  }
}
