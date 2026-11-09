import 'package:flutter/material.dart';

import '../core/meal_type.dart';

/// 끼니별 아이콘과 색
({IconData icon, Color color}) mealStyle(String type) => switch (type) {
  MealType.breakfast => (
    icon: Icons.wb_twilight_rounded,
    color: const Color(0xFFF97316),
  ),
  MealType.lunch => (
    icon: Icons.wb_sunny_rounded,
    color: const Color(0xFFEAB308),
  ),
  MealType.dinner => (
    icon: Icons.nightlight_round,
    color: const Color(0xFF6366F1),
  ),
  _ => (icon: Icons.cookie_rounded, color: const Color(0xFFEC4899)),
};

/// 끼니 아이콘 배지
class MealBadge extends StatelessWidget {
  const MealBadge({super.key, required this.type, this.size = 32});
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = mealStyle(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: s.color.withAlpha(36),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(s.icon, size: size * 0.56, color: s.color),
    );
  }
}
