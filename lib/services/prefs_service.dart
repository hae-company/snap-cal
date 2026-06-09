import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PrefsService {
  static const _keyGoal = 'daily_goal';
  static const _keyApiKey = 'gemini_api_key';
  static const _keyDark = 'dark_mode';
  // 식사 시간대 (HH 형식으로 저장)
  static const _keyBreakfastStart = 'meal_breakfast_start';
  static const _keyBreakfastEnd = 'meal_breakfast_end';
  static const _keyLunchStart = 'meal_lunch_start';
  static const _keyLunchEnd = 'meal_lunch_end';
  static const _keyDinnerStart = 'meal_dinner_start';
  static const _keyDinnerEnd = 'meal_dinner_end';

  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGoal) ?? 2000;
  }

  static Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, goal);
  }

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? '';
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDark) ?? false;
  }

  static Future<void> setDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, v);
  }

  // 식사 시간대
  static Future<Map<String, List<int>>> getMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      MealType.breakfast: [
        prefs.getInt(_keyBreakfastStart) ?? 6,
        prefs.getInt(_keyBreakfastEnd) ?? 10,
      ],
      MealType.lunch: [
        prefs.getInt(_keyLunchStart) ?? 11,
        prefs.getInt(_keyLunchEnd) ?? 14,
      ],
      MealType.dinner: [
        prefs.getInt(_keyDinnerStart) ?? 17,
        prefs.getInt(_keyDinnerEnd) ?? 21,
      ],
    };
  }

  static Future<void> setMealTimes(Map<String, List<int>> times) async {
    final prefs = await SharedPreferences.getInstance();
    final b = times[MealType.breakfast]!;
    final l = times[MealType.lunch]!;
    final d = times[MealType.dinner]!;
    await prefs.setInt(_keyBreakfastStart, b[0]);
    await prefs.setInt(_keyBreakfastEnd, b[1]);
    await prefs.setInt(_keyLunchStart, l[0]);
    await prefs.setInt(_keyLunchEnd, l[1]);
    await prefs.setInt(_keyDinnerStart, d[0]);
    await prefs.setInt(_keyDinnerEnd, d[1]);
  }

  /// 현재 시각 기준으로 식사 종류 자동 판별
  static Future<String> autoDetectMealType() async {
    final hour = DateTime.now().hour;
    final times = await getMealTimes();

    final b = times[MealType.breakfast]!;
    if (hour >= b[0] && hour < b[1]) return MealType.breakfast;

    final l = times[MealType.lunch]!;
    if (hour >= l[0] && hour < l[1]) return MealType.lunch;

    final d = times[MealType.dinner]!;
    if (hour >= d[0] && hour < d[1]) return MealType.dinner;

    return MealType.snack;
  }
}
