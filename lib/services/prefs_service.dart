import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _keyGoal = 'daily_goal';
  static const _keyApiKey = 'gemini_api_key';
  static const _keyDark = 'dark_mode';

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
}
