import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/date_key.dart';
import '../core/nutrition_calc.dart';
import 'models/food_record.dart';
import 'repositories/food_analysis_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/settings_repository.dart';

// ───────── 저장소 ─────────

/// main()에서 실제 인스턴스로 덮어쓴다.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main()에서 override 해야 합니다'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => PrefsMealRepository(ref.watch(sharedPreferencesProvider)),
);

final foodAnalysisRepositoryProvider = Provider<FoodAnalysisRepository>(
  (ref) => GeminiDirectAnalysisRepository(() => ref.read(apiKeyProvider)),
);

// ───────── 설정 상태 ─────────

class GoalsNotifier extends Notifier<NutritionGoals> {
  @override
  NutritionGoals build() => ref.watch(settingsRepositoryProvider).goals;

  Future<void> save(NutritionGoals goals) async {
    await ref.read(settingsRepositoryProvider).setGoals(goals);
    state = goals;
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, NutritionGoals>(
  GoalsNotifier.new,
);

class OnboardedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).onboarded;

  Future<void> complete() async {
    await ref.read(settingsRepositoryProvider).setOnboarded(true);
    state = true;
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(settingsRepositoryProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(settingsRepositoryProvider).apiKey;

  Future<void> set(String key) async {
    await ref.read(settingsRepositoryProvider).setApiKey(key);
    state = key;
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(
  ApiKeyNotifier.new,
);

final mealTimesProvider = Provider<Map<String, List<int>>>(
  (ref) => ref.watch(settingsRepositoryProvider).mealTimes,
);

// ───────── 식단 기록 조회 ─────────

/// 날짜 범위 [from, to] 의 기록 (yyyy-MM-dd)
final mealsInRangeProvider =
    FutureProvider.family<List<FoodRecord>, ({String from, String to})>(
      (ref, range) =>
          ref.watch(mealRepositoryProvider).inRange(range.from, range.to),
    );

final mealsByDateProvider = FutureProvider.family<List<FoodRecord>, String>(
  (ref, date) => ref.watch(mealsInRangeProvider((from: date, to: date)).future),
);

/// 해당 월의 날짜 → 총 칼로리
final monthCaloriesProvider =
    FutureProvider.family<Map<String, int>, ({int year, int month})>((
      ref,
      m,
    ) async {
      final from = dateKey(DateTime(m.year, m.month, 1));
      final to = dateKey(DateTime(m.year, m.month + 1, 0));
      final records = await ref.watch(
        mealsInRangeProvider((from: from, to: to)).future,
      );
      return caloriesByDate(records);
    });

/// 자주 먹은 음식 (이름, 횟수) 상위 N개
final topFoodsProvider = FutureProvider.family<List<(String, int)>, int>((
  ref,
  limit,
) async {
  final records = await ref.watch(mealRepositoryProvider).all();
  return topFoods(records, limit);
});

Map<String, int> caloriesByDate(Iterable<FoodRecord> records) {
  final map = <String, int>{};
  for (final r in records) {
    map[r.date] = (map[r.date] ?? 0) + r.calories;
  }
  return map;
}

List<(String, int)> topFoods(Iterable<FoodRecord> records, int limit) {
  final counts = <String, int>{};
  for (final r in records) {
    counts[r.foodName] = (counts[r.foodName] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in sorted.take(limit)) (e.key, e.value)];
}

// ───────── 식단 기록 변경 ─────────

/// 기록을 바꾸고, 관련 조회 결과를 모두 새로 고친다.
class MealActions {
  MealActions(this._ref);
  final Ref _ref;

  MealRepository get _repo => _ref.read(mealRepositoryProvider);

  void _refresh() {
    _ref.invalidate(mealsInRangeProvider);
    _ref.invalidate(topFoodsProvider);
  }

  Future<void> add(FoodRecord record) async {
    await _repo.insert(record);
    _refresh();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _refresh();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    _refresh();
  }
}

final mealActionsProvider = Provider<MealActions>(MealActions.new);
