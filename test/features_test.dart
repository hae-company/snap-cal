import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_cal/core/daily_tip.dart';
import 'package:snap_cal/core/nutrition_calc.dart';
import 'package:snap_cal/data/models/food_record.dart';
import 'package:snap_cal/data/providers.dart';
import 'package:snap_cal/data/repositories/body_log_repository.dart';
import 'package:snap_cal/data/repositories/food_catalog_repository.dart';
import 'package:snap_cal/data/repositories/settings_repository.dart';
import 'package:snap_cal/data/services/export_service.dart';
import 'package:snap_cal/data/services/photo_store.dart';

FoodRecord rec(
  String name, {
  int kcal = 300,
  double servings = 1,
  DateTime? at,
  String date = '2026-11-09',
}) => FoodRecord(
  date: date,
  mealType: 'lunch',
  foodName: name,
  calories: kcal,
  carbs: 40,
  protein: 20,
  fat: 10,
  servings: servings,
  createdAt: at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('음식 검색', () {
    late List<dynamic> foods;
    setUpAll(() async => foods = await FoodCatalogRepository(rootBundle).all());

    test('내장 목록을 읽는다', () {
      expect(foods.length, greaterThan(150));
    });

    test('이름·별칭·초성으로 찾고, 정확히 같은 이름이 먼저', () async {
      final repo = FoodCatalogRepository(rootBundle);
      expect((await repo.search('김치찌개')).first.name, '김치찌개');
      expect((await repo.search('ㄱㅊㅉㄱ')).first.name, '김치찌개');
      expect((await repo.search('돈까스')).first.name, '돈가스'); // 별칭
      expect((await repo.search('아아')).first.name, '아메리카노');
      expect((await repo.search('치킨')).map((f) => f.name), contains('양념치킨'));
      expect(await repo.search('   '), isEmpty);
    });

    test('초성 변환', () {
      expect(choseong('삼겹살 1인분'), 'ㅅㄱㅅ 1ㅇㅂ');
    });
  });

  test('양 바꾸기: 1인분 기준으로 되돌려 새 배수를 곱한다', () {
    final r = rec('비빔밥', kcal: 600, servings: 1.5);
    final half = r.withServings(0.5);
    expect(half.servings, 0.5);
    expect(half.calories, 200);
    expect(half.carbs, 13);
    expect(r.withServings(1.5).calories, 600);
  });

  test('예전 기록(인분·출처 없음)도 읽는다', () {
    final r = FoodRecord.fromMap({
      'id': 1,
      'date': '2026-11-01',
      'meal_type': 'lunch',
      'food_name': '라면',
      'calories': 500,
      'carbs': 79,
      'protein': 10,
      'fat': 16,
      'created_at': '2026-11-01T12:00:00.000',
    });
    expect(r.servings, 1);
    expect(r.source, isNull);
  });

  test('최근·자주 먹은 음식', () {
    final q = quickFoods([
      rec('라면', at: DateTime(2026, 11, 1)),
      rec('김밥', at: DateTime(2026, 11, 3)),
      rec('라면', kcal: 520, at: DateTime(2026, 11, 2)),
      rec('샐러드', at: DateTime(2026, 11, 4)),
    ]);
    expect(q.recent.map((r) => r.foodName), ['샐러드', '김밥', '라면']);
    expect(q.recent.last.calories, 520); // 같은 음식은 가장 최근 값
    expect(q.frequent.map((r) => r.foodName), ['라면']);
  });

  group('오늘의 한마디', () {
    const g = NutritionGoals(kcal: 2000, carbsG: 250, proteinG: 100, fatG: 55);
    DailyTip tip({
      int h = 12,
      int n = 1,
      int kcal = 1000,
      int protein = 80,
      int fat = 30,
      int water = 1500,
    }) => dailyTip(
      now: DateTime(2026, 11, 9, h),
      recordCount: n,
      kcal: kcal,
      protein: protein,
      fat: fat,
      goals: g,
      waterMl: water,
      waterGoalMl: 2000,
    );

    test('규칙 우선순위', () {
      expect(tip(n: 0).kind, TipKind.start);
      expect(tip(kcal: 2300).kind, TipKind.over);
      expect(tip(h: 16, protein: 30).kind, TipKind.protein);
      expect(
        tip(h: 12, protein: 30).kind,
        isNot(TipKind.protein),
      ); // 오후 전에는 단백질 경고 안 함
      expect(tip(h: 15, water: 250).kind, TipKind.water);
      expect(tip(fat: 70).kind, TipKind.fat);
      expect(tip(kcal: 1850).kind, TipKind.almost);
      expect(tip().kind, TipKind.good);
    });
  });

  test('CSV: 날짜순, 쉼표가 든 이름은 따옴표로 감싼다', () {
    final csv = buildMealsCsv([
      rec('B', date: '2026-11-02'),
      rec('계란, 토스트', date: '2026-11-01'),
    ]);
    final lines = csv.trimRight().split('\n');
    expect(lines.first, startsWith('﻿날짜,끼니'));
    expect(lines[1], '2026-11-01,점심,"계란, 토스트",1,300,40,20,10');
    expect(lines[2], startsWith('2026-11-02,점심,B'));
  });

  group('물·체중·알림 설정', () {
    test('물과 체중 기록', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = BodyLogRepository(await SharedPreferences.getInstance());
      await repo.setWater('2026-11-09', 750);
      expect(repo.waterOn('2026-11-09'), 750);
      expect(repo.waterOn('2026-11-08'), 0);

      await repo.setWeight('2026-11-09', 64.26);
      await repo.setWeight('2026-11-01', 65);
      expect(repo.weights(), [('2026-11-01', 65.0), ('2026-11-09', 64.3)]);
      await repo.deleteWeight('2026-11-01');
      expect(repo.weights().length, 1);
    });

    test('알림 기본값은 모두 꺼짐, 저장 후 다시 읽힌다', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsRepository(await SharedPreferences.getInstance());
      expect(s.reminders.every((r) => !r.enabled), isTrue);
      await s.setReminders([
        s.reminders.first.copyWith(enabled: true, hour: 7, minute: 5),
      ]);
      expect(s.reminders.single.timeLabel, '07:05');
      expect(s.reminders.single.enabled, isTrue);
    });
  });

  group('사진 보관', () {
    late Directory tmp;
    setUp(
      () async => tmp = await Directory.systemTemp.createTemp('snapcal_photos'),
    );
    tearDown(() async {
      PhotoStore.debugSetDirectory(null);
      await tmp.delete(recursive: true);
    });

    test('보관 폴더로 복사하고 상대 경로로 저장, 지우면 파일도 사라진다', () async {
      PhotoStore.debugSetDirectory(tmp);
      final src = File('${tmp.path}/picked.jpg')..writeAsBytesSync([1, 2, 3]);

      final stored = await PhotoStore.keep(src.path);
      expect(stored, startsWith('meal_photos/'));
      final file = File(PhotoStore.resolve(stored)!);
      expect(file.readAsBytesSync(), [1, 2, 3]);

      await PhotoStore.delete(stored);
      expect(file.existsSync(), isFalse);
    });

    test('예전 기록의 절대 경로는 그대로 쓰고, 지우지 않는다', () async {
      PhotoStore.debugSetDirectory(tmp);
      final old = File('${tmp.path}/old.jpg')..writeAsBytesSync([9]);
      expect(PhotoStore.resolve(old.path), old.path);
      await PhotoStore.delete(old.path);
      expect(old.existsSync(), isTrue);
      expect(PhotoStore.resolve(null), isNull);
    });
  });
}
