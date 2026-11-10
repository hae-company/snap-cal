import 'dart:convert';

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

  // 물 목표 (ml)
  static const _kWaterGoal = 'water_goal';
  int get waterGoal => _prefs.getInt(_kWaterGoal) ?? 2000;
  Future<void> setWaterGoal(int ml) => _prefs.setInt(_kWaterGoal, ml);

  // 목표 체중 (kg, 없으면 null)
  static const _kTargetWeight = 'target_weight';
  double? get targetWeight => _prefs.getDouble(_kTargetWeight);
  Future<void> setTargetWeight(double? kg) => kg == null
      ? _prefs.remove(_kTargetWeight)
      : _prefs.setDouble(_kTargetWeight, kg);

  // 무료 AI 분석 사용 횟수 (결제가 켜졌을 때만 센다). 서버 전환 후에는 서버 값이 기준.
  static const _kFreeAnalyses = 'free_analyses_used';
  int get freeAnalysesUsed => _prefs.getInt(_kFreeAnalyses) ?? 0;
  Future<void> setFreeAnalysesUsed(int n) => _prefs.setInt(_kFreeAnalyses, n);

  // 광고로 받은 AI 분석 횟수 (남은 개수) · 오늘 광고 본 횟수
  static const _kBonus = 'bonus_analyses';
  static const _kAdDay = 'ad_reward_day';
  static const _kAdCount = 'ad_reward_count';

  int get bonusAnalyses => _prefs.getInt(_kBonus) ?? 0;
  Future<void> setBonusAnalyses(int n) => _prefs.setInt(_kBonus, n);

  /// [day] (yyyy-MM-dd)에 광고 보상을 받은 횟수
  int adRewardsOn(String day) =>
      _prefs.getString(_kAdDay) == day ? (_prefs.getInt(_kAdCount) ?? 0) : 0;

  Future<void> setAdRewards(String day, int count) async {
    await _prefs.setString(_kAdDay, day);
    await _prefs.setInt(_kAdCount, count);
  }

  // 끼니 알림
  static const _kReminders = 'meal_reminders';
  List<MealReminder> get reminders {
    final raw = _prefs.getString(_kReminders);
    if (raw == null) return MealReminder.defaults;
    final list = jsonDecode(raw) as List;
    return [
      for (final e in list) MealReminder.fromMap(e as Map<String, dynamic>),
    ];
  }

  Future<void> setReminders(List<MealReminder> list) => _prefs.setString(
    _kReminders,
    jsonEncode([for (final r in list) r.toMap()]),
  );

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

/// 끼니 기록 알림 (매일 같은 시각)
class MealReminder {
  const MealReminder({
    required this.mealType,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final String mealType;
  final bool enabled;
  final int hour;
  final int minute;

  /// 처음에는 모두 꺼 둔다. 사용자가 켤 때 알림 권한을 묻는다.
  static const defaults = [
    MealReminder(
      mealType: MealType.breakfast,
      enabled: false,
      hour: 8,
      minute: 0,
    ),
    MealReminder(
      mealType: MealType.lunch,
      enabled: false,
      hour: 12,
      minute: 30,
    ),
    MealReminder(
      mealType: MealType.dinner,
      enabled: false,
      hour: 18,
      minute: 30,
    ),
  ];

  MealReminder copyWith({bool? enabled, int? hour, int? minute}) =>
      MealReminder(
        mealType: mealType,
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toMap() => {
    'meal': mealType,
    'on': enabled,
    'h': hour,
    'm': minute,
  };

  factory MealReminder.fromMap(Map<String, dynamic> m) => MealReminder(
    mealType: m['meal'] as String,
    enabled: m['on'] as bool,
    hour: m['h'] as int,
    minute: m['m'] as int,
  );

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
