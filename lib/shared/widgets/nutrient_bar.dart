import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 영양소 하나의 현재/목표 막대
class NutrientBar extends StatelessWidget {
  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.unit = 'g',
    this.showRemaining = false,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final String unit;
  final bool showRemaining;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final over = max > 0 && value > max;
    final remaining = max - value;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: p.surfaceAlt,
                  color: over ? p.over : color,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            SizedBox(
              width: 76,
              child: Text(
                '$value / $max$unit',
                textAlign: TextAlign.right,
                style: AppText.numeric(
                  AppText.micro,
                ).copyWith(fontSize: 12, color: over ? p.over : p.text1),
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
                over ? '${-remaining}$unit 초과' : '$remaining$unit 남음',
                style: AppText.micro.copyWith(
                  fontWeight: FontWeight.w500,
                  color: over ? p.over : p.text3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
