import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/meal_type.dart';
import '../../core/nutrition_calc.dart';

/// 사용자 설정 저장소. 지금은 기기(SharedPreferences)에 저장한다.
/// 1단계(계정과 데이터)에서 목표·설정은 Firestore `users/{uid}`로 옮긴다.
///
/// 저장 키는 기존 앱과 같게 유지해 업데이트해도 설정이 그대로 남는다.
class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kGoal = 'daily_goal';
  static const _kCarbs = 'carbs_goal';
  static const _kProtein = 'protein_goal';
  static const _kFat = 'fat_goal';
  static const _kOnboarded = 'onboarded';
  static const _kApiKey = 'gemini_api_key';
  static const _kThemeMode = 'theme_mode';
  static const _kLegacyDark = 'dark_mode';

  static const _mealTimeKeys = {
    MealType.breakfast: ('meal_breakfast_start', 'meal_breakfast_end', 6, 10),
    MealType.lunch: ('meal_lunch_start', 'meal_lunch_end', 11, 14),
    MealType.dinner: ('meal_dinner_start', 'meal_dinner_end', 17, 21),
  };

  // 목표
  NutritionGoals get goals {
    final d = NutritionGoals.defaults;
    return NutritionGoals(
      kcal: _prefs.getInt(_kGoal) ?? d.kcal,
      carbsG: _prefs.getInt(_kCarbs) ?? d.carbsG,
      proteinG: _prefs.getInt(_kProtein) ?? d.proteinG,
      fatG: _prefs.getInt(_kFat) ?? d.fatG,
    );
  }

  Future<void> setGoals(NutritionGoals g) async {
    await _prefs.setInt(_kGoal, g.kcal);
    await _prefs.setInt(_kCarbs, g.carbsG);
    await _prefs.setInt(_kProtein, g.proteinG);
    await _prefs.setInt(_kFat, g.fatG);
  }

  // 온보딩
  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) => _prefs.setBool(_kOnboarded, v);

  // Gemini API 키 (2단계에서 서버 호출로 바꾸면서 삭제)
  String get apiKey => _prefs.getString(_kApiKey) ?? '';
  Future<void> setApiKey(String v) => _prefs.setString(_kApiKey, v);

  // 화면 테마. 예전 버전의 dark_mode(bool) 값도 읽는다.
  ThemeMode get themeMode {
    final saved = _prefs.getString(_kThemeMode);
    if (saved != null) {
      return ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
    return (_prefs.getBool(_kLegacyDark) ?? false)
        ? ThemeMode.dark
        : ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode m) =>
      _prefs.setString(_kThemeMode, m.name);

  // 끼니 시간대 (시 단위, [시작, 끝))
  Map<String, List<int>> get mealTimes => {
    for (final e in _mealTimeKeys.entries)
      e.key: [
        _prefs.getInt(e.value.$1) ?? e.value.$3,
        _prefs.getInt(e.value.$2) ?? e.value.$4,
      ],
  };

  Future<void> setMealTimes(Map<String, List<int>> times) async {
    for (final e in _mealTimeKeys.entries) {
      final range = times[e.key];
      if (range == null) continue;
      await _prefs.setInt(e.value.$1, range[0]);
      await _prefs.setInt(e.value.$2, range[1]);
    }
  }
}
