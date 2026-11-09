import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../meal_style.dart';

/// 끼니 4개 중 하나 고르기
class MealPicker extends StatelessWidget {
  const MealPicker({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in MealType.all) ...[
          Expanded(
            child: _MealOption(
              type: t,
              selected: value == t,
              onTap: () => onChanged(t),
            ),
          ),
          if (t != MealType.all.last) const SizedBox(width: AppSpace.xs),
        ],
      ],
    );
  }
}

class _MealOption extends StatelessWidget {
  const _MealOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });
  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.brandSubtle : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(
            color: selected ? p.brand : p.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Column(
              children: [
                MealBadge(type: type, size: 30),
                const SizedBox(height: 6),
                Text(
                  MealType.label(type),
                  style: AppText.label.copyWith(
                    color: selected ? p.text1 : p.text2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 몇 인분인지 0.5 단위로 고르기 (0.5 ~ 5)
class ServingStepper extends StatelessWidget {
  const ServingStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.unit = '인분',
  });
  final double value;
  final ValueChanged<double> onChanged;
  final String unit;

  static const presets = [0.5, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget round(IconData icon, String tip, double next) =>
        IconButton.filledTonal(
          tooltip: tip,
          onPressed: next < 0.5 || next > 5
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged(next);
                },
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: p.surfaceAlt,
            foregroundColor: p.text1,
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            round(Icons.remove_rounded, '줄이기', value - 0.5),
            Expanded(
              child: Text(
                '${formatServings(value)} $unit',
                textAlign: TextAlign.center,
                style: AppText.numeric(AppText.title2),
              ),
            ),
            round(Icons.add_rounded, '늘리기', value + 0.5),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            for (final v in presets) ...[
              Expanded(
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(formatServings(v), textAlign: TextAlign.center),
                  ),
                  selected: value == v,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(v),
                  selectedColor: p.brandSubtle,
                  side: BorderSide(color: value == v ? p.brand : p.border),
                  labelStyle: AppText.label.copyWith(
                    color: value == v ? p.brandPressed : p.text2,
                  ),
                ),
              ),
              if (v != presets.last) const SizedBox(width: AppSpace.xs),
            ],
          ],
        ),
      ],
    );
  }
}

String formatServings(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
