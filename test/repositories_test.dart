import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_cal/core/nutrition_calc.dart';
import 'package:snap_cal/data/models/food_record.dart';
import 'package:snap_cal/data/repositories/meal_repository.dart';
import 'package:snap_cal/data/repositories/settings_repository.dart';

FoodRecord rec(String date, String name, {int kcal = 100, DateTime? at}) =>
    FoodRecord(
      date: date,
      mealType: 'lunch',
      foodName: name,
      calories: kcal,
      carbs: 10,
      protein: 5,
      fat: 2,
      createdAt: at,
    );

void main() {
  group('PrefsMealRepository', () {
    test('기존 앱이 저장한 기록을 그대로 읽는다', () async {
      // 이전 버전(DatabaseService)이 남긴 JSON 형식
      final legacy = [
        {
          'id': 7,
          'date': '2026-11-01',
          'meal_type': 'dinner',
          'food_name': '김치찌개',
          'calories': 550,
          'carbs': 75,
          'protein': 22,
          'fat': 15,
          'image_path': '/tmp/a.jpg',
          'description': '김치찌개, 밥',
          'created_at': '2026-11-01T19:00:00.000',
        },
      ];
      SharedPreferences.setMockInitialValues({
        'food_records': jsonEncode(legacy),
      });
      final repo = PrefsMealRepository(await SharedPreferences.getInstance());

      final all = await repo.all();
      expect(all.single.foodName, '김치찌개');
      expect(all.single.id, 7);

      // 새 기록은 기존 최대 id 다음 번호
      expect(await repo.insert(rec('2026-11-02', '비빔밥')), 8);
    });

    test('범위 조회는 날짜 → 시각 순, 삭제와 전체 삭제', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsMealRepository(await SharedPreferences.getInstance());

      final a = await repo.insert(
        rec('2026-11-03', 'C', at: DateTime(2026, 11, 3, 12)),
      );
      await repo.insert(rec('2026-11-02', 'B', at: DateTime(2026, 11, 2, 9)));
      await repo.insert(rec('2026-11-03', 'D', at: DateTime(2026, 11, 3, 8)));
      await repo.insert(rec('2026-11-10', 'out'));

      final week = await repo.inRange('2026-11-02', '2026-11-08');
      expect(week.map((r) => r.foodName), ['B', 'D', 'C']);

      await repo.delete(a);
      expect(
        (await repo.inRange('2026-11-03', '2026-11-03')).map((r) => r.foodName),
        ['D'],
      );

      await repo.deleteAll();
      expect(await repo.all(), isEmpty);
    });
  });

  group('SettingsRepository', () {
    test('기본값', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsRepository(await SharedPreferences.getInstance());
      expect(s.goals, NutritionGoals.defaults);
      expect(s.onboarded, isFalse);
      expect(s.themeMode, ThemeMode.system);
      expect(s.mealTimes['lunch'], [11, 14]);
    });

    test('예전 dark_mode 값을 테마로 이어받는다', () async {
      SharedPreferences.setMockInitialValues({'dark_mode': true});
      final s = SettingsRepository(await SharedPreferences.getInstance());
      expect(s.themeMode, ThemeMode.dark);

      await s.setThemeMode(ThemeMode.light);
      expect(s.themeMode, ThemeMode.light);
    });

    test('목표 저장', () async {
      SharedPreferences.setMockInitialValues({'daily_goal': 1800});
      final s = SettingsRepository(await SharedPreferences.getInstance());
      expect(s.goals.kcal, 1800);

      const g = NutritionGoals(
        kcal: 2100,
        carbsG: 260,
        proteinG: 120,
        fatG: 60,
      );
      await s.setGoals(g);
      expect(s.goals, g);
    });
  });
}
