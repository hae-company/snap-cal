import 'package:flutter_test/flutter_test.dart';
import 'package:snap_cal/core/date_key.dart';
import 'package:snap_cal/core/meal_type.dart';
import 'package:snap_cal/core/nutrition_calc.dart';
import 'package:snap_cal/data/providers.dart';
import 'package:snap_cal/data/repositories/food_analysis_repository.dart';
import 'package:snap_cal/features/log/calendar_screen.dart';

void main() {
  group('MealType.detect', () {
    final times = {
      MealType.breakfast: [6, 10],
      MealType.lunch: [11, 14],
      MealType.dinner: [17, 21],
    };
    DateTime at(int h) => DateTime(2026, 11, 9, h, 30);

    test('시간대 안이면 해당 끼니', () {
      expect(MealType.detect(at(7), times), MealType.breakfast);
      expect(MealType.detect(at(12), times), MealType.lunch);
      expect(MealType.detect(at(18), times), MealType.dinner);
    });

    test('끝 시각은 포함하지 않고, 사이 시간은 간식', () {
      expect(MealType.detect(at(10), times), MealType.snack);
      expect(MealType.detect(at(15), times), MealType.snack);
      expect(MealType.detect(at(23), times), MealType.snack);
    });
  });

  group('nutrition', () {
    test('TDEE는 기존 앱 공식과 같은 값', () {
      // 남성 25세 170cm 65kg 가벼운 활동: (88.362 + 870.805 + 815.83 - 141.925) * 1.375
      expect(
        calcTdee(
          male: true,
          age: 25,
          heightCm: 170,
          weightKg: 65,
          activityIndex: 1,
        ),
        2245,
      );
      expect(
        calcTdee(
          male: false,
          age: 25,
          heightCm: 170,
          weightKg: 65,
          activityIndex: 0,
        ),
        1760,
      );
    });

    test('탄단지 50/30/20 분배', () {
      final g = NutritionGoals.fromKcal(2000);
      expect(g.carbsG, 250);
      expect(g.proteinG, 150);
      expect(g.fatG, 44);
    });
  });

  test('mondayOf', () {
    expect(mondayOf(DateTime(2026, 11, 9)), DateTime(2026, 11, 9)); // 월요일
    expect(
      mondayOf(DateTime(2026, 11, 15, 22)),
      DateTime(2026, 11, 9),
    ); // 일요일 밤
    expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('extractJsonObject', () {
    expect(extractJsonObject('```json\n{"a":1}\n```'), '{"a":1}');
    expect(extractJsonObject('no json'), isNull);
  });

  test('연속 기록일: 오늘 기록이 없으면 어제부터 센다', () {
    final now = DateTime(2026, 11, 9, 20);
    expect(recordStreak({'2026-11-09', '2026-11-08', '2026-11-06'}, now), 2);
    expect(recordStreak({'2026-11-08', '2026-11-07'}, now), 2);
    expect(recordStreak({'2026-11-07'}, now), 0);
  });

  test('캘린더 날짜 상태', () {
    expect(dayStatus(null, 2000), DayStatus.none);
    expect(dayStatus(1700, 2000), DayStatus.under);
    expect(dayStatus(1800, 2000), DayStatus.onTrack);
    expect(dayStatus(2200, 2000), DayStatus.onTrack);
    expect(dayStatus(2201, 2000), DayStatus.over);
  });
}
