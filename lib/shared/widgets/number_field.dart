import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

/// 숫자 입력칸 (라벨 + 색 점)
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.unit,
    required this.color,
    this.decimal = false,
    this.hint,
  });
  final String label;
  final TextEditingController controller;
  final String unit;
  final Color color;

  /// 소수점 한 자리까지 허용 (체중 등)
  final bool decimal;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppText.caption.copyWith(color: p.text2)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            decimal
                ? FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?'))
                : FilteringTextInputFormatter.digitsOnly,
          ],
          style: AppText.numeric(AppText.headline),
          decoration: InputDecoration(
            suffixText: unit,
            hintText: hint,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
