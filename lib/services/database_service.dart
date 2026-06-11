import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_record.dart';

// Web: shared_preferences JSON storage
// Mobile: also shared_preferences for simplicity (cross-platform)
class DatabaseService {
  static const _key = 'food_records';
  static int _nextId = 1;

  static Future<List<FoodRecord>> _getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    final records = list.map((e) => FoodRecord.fromMap(e as Map<String, dynamic>)).toList();
    if (records.isNotEmpty) {
      _nextId = records.map((r) => r.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    }
    return records;
  }

  static Future<void> _saveAll(List<FoodRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toMap()).toList()));
  }

  // Expose for settings reset
  static Future<SharedPreferences> get database async => SharedPreferences.getInstance();

  static Future<int> insert(FoodRecord record) async {
    final records = await _getAll();
    final id = _nextId++;
    final newRecord = FoodRecord(
      id: id,
      date: record.date,
      mealType: record.mealType,
      foodName: record.foodName,
      calories: record.calories,
      carbs: record.carbs,
      protein: record.protein,
      fat: record.fat,
      imagePath: kIsWeb ? null : record.imagePath, // web has no local file paths
      description: record.description,
      createdAt: record.createdAt,
    );
    records.add(newRecord);
    await _saveAll(records);
    return id;
  }

  static Future<List<FoodRecord>> getByDate(String date) async {
    final records = await _getAll();
    return records.where((r) => r.date == date).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<Map<String, int>> getCaloriesByDateRange(String from, String to) async {
    final records = await _getAll();
    final filtered = records.where((r) => r.date.compareTo(from) >= 0 && r.date.compareTo(to) <= 0);
    final map = <String, int>{};
    for (final r in filtered) {
      map[r.date] = (map[r.date] ?? 0) + r.calories;
    }
    return map;
  }

  static Future<List<FoodRecord>> getByDateRange(String from, String to) async {
    final records = await _getAll();
    return records
        .where((r) => r.date.compareTo(from) >= 0 && r.date.compareTo(to) <= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date) != 0 ? a.date.compareTo(b.date) : a.createdAt.compareTo(b.createdAt));
  }

  static Future<int> delete(int id) async {
    final records = await _getAll();
    records.removeWhere((r) => r.id == id);
    await _saveAll(records);
    return 1;
  }

  static Future<List<Map<String, dynamic>>> topFoods(int limit) async {
    final records = await _getAll();
    final counts = <String, int>{};
    for (final r in records) {
      counts[r.foodName] = (counts[r.foodName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => {'food_name': e.key, 'count': e.value}).toList();
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
