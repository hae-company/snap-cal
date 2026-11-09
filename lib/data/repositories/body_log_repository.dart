import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 물 섭취(ml)와 체중(kg) 기록. 날짜(yyyy-MM-dd) → 값.
///
/// 1단계(계정과 데이터)에서 Firestore `users/{uid}/water`, `weights`로 옮긴다.
class BodyLogRepository {
  BodyLogRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kWater = 'water_log';
  static const _kWeight = 'weight_log';

  Map<String, num> _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as num),
    );
  }

  Future<void> _writeMap(String key, Map<String, num> map) =>
      _prefs.setString(key, jsonEncode(map));

  // 물
  int waterOn(String date) => (_readMap(_kWater)[date] ?? 0).toInt();

  Future<void> setWater(String date, int ml) async {
    final map = _readMap(_kWater);
    if (ml <= 0) {
      map.remove(date);
    } else {
      map[date] = ml;
    }
    await _writeMap(_kWater, map);
  }

  // 체중
  /// 날짜 오름차순
  List<(String, double)> weights() {
    final entries = _readMap(_kWeight).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [for (final e in entries) (e.key, e.value.toDouble())];
  }

  Future<void> setWeight(String date, double kg) async {
    final map = _readMap(_kWeight)
      ..[date] = double.parse(kg.toStringAsFixed(1));
    await _writeMap(_kWeight, map);
  }

  Future<void> deleteWeight(String date) async {
    final map = _readMap(_kWeight)..remove(date);
    await _writeMap(_kWeight, map);
  }

  Future<void> clear() async {
    await _prefs.remove(_kWater);
    await _prefs.remove(_kWeight);
  }
}
