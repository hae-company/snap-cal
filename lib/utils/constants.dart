import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFFE8F5E9);
  static const accent = Color(0xFF66BB6A);
  static const background = Color(0xFFFAFAFA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const divider = Color(0xFFEEEEEE);
  static const danger = Color(0xFFE57373);
  static const carbs = Color(0xFF42A5F5);
  static const protein = Color(0xFFEF5350);
  static const fat = Color(0xFFFFCA28);
}

class MealType {
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';

  static String label(String type) {
    switch (type) {
      case breakfast: return '아침';
      case lunch: return '점심';
      case dinner: return '저녁';
      case snack: return '간식';
      default: return '';
    }
  }

  static String emoji(String type) {
    switch (type) {
      case breakfast: return '🌅';
      case lunch: return '☀️';
      case dinner: return '🌙';
      case snack: return '🍪';
      default: return '';
    }
  }
}
