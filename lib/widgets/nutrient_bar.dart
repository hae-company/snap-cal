import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NutrientBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String unit;

  const NutrientBar({super.key, required this.label, required this.value, required this.max, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: Text('$value$unit', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
