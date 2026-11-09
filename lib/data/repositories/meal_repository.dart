import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_record.dart';

/// 식단 기록 저장소.
///
/// 화면은 이 인터페이스만 쓴다. 1단계에서 Firestore 구현으로 바꿔 끼운다.
abstract interface class MealRepository {
  Future<List<FoodRecord>> all();

  /// 날짜(yyyy-MM-dd) 범위 [from, to] 의 기록. 날짜 → 저장 시각 순.
  Future<List<FoodRecord>> inRange(String from, String to);

  Future<int> insert(FoodRecord record);
  Future<void> delete(int id);
  Future<void> deleteAll();
}

/// 기기 저장 구현. 기존 앱과 같은 키(`food_records`)와 JSON 형식을 쓴다.
class PrefsMealRepository implements MealRepository {
  PrefsMealRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'food_records';

  List<FoodRecord> _read() {
    final json = _prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => FoodRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(List<FoodRecord> records) => _prefs.setString(
    _key,
    jsonEncode(records.map((r) => r.toMap()).toList()),
  );

  @override
  Future<List<FoodRecord>> all() async => _read();

  @override
  Future<List<FoodRecord>> inRange(String from, String to) async {
    return _read()
        .where((r) => r.date.compareTo(from) >= 0 && r.date.compareTo(to) <= 0)
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
      });
  }

  @override
  Future<int> insert(FoodRecord record) async {
    final records = _read();
    final nextId =
        records.fold<int>(0, (m, r) => (r.id ?? 0) > m ? r.id! : m) + 1;
    records.add(
      record.copyWith(
        id: nextId,
        // 웹에는 로컬 파일 경로가 없다
        imagePath: kIsWeb ? null : record.imagePath,
        clearImagePath: kIsWeb,
      ),
    );
    await _write(records);
    return nextId;
  }

  @override
  Future<void> delete(int id) async {
    final records = _read()..removeWhere((r) => r.id == id);
    await _write(records);
  }

  @override
  Future<void> deleteAll() => _prefs.remove(_key);
}
