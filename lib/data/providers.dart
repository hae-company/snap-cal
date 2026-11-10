import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/date_key.dart';
import '../core/nutrition_calc.dart';
import 'models/food_record.dart';
import 'repositories/body_log_repository.dart';
import 'repositories/food_analysis_repository.dart';
import 'repositories/food_catalog_repository.dart';
import 'repositories/meal_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/photo_store.dart';
import 'services/reminder_service.dart';

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

final bodyLogRepositoryProvider = Provider<BodyLogRepository>(
  (ref) => BodyLogRepository(ref.watch(sharedPreferencesProvider)),
);

final foodCatalogRepositoryProvider = Provider<FoodCatalogRepository>(
  (ref) => FoodCatalogRepository(rootBundle),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => LocalReminderService(),
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

/// 오늘(또는 오늘 기록이 아직 없으면 어제)부터 거꾸로 이어진 기록일 수
final streakProvider = FutureProvider<int>((ref) async {
  final records = await ref.watch(mealRepositoryProvider).all();
  return recordStreak(records.map((r) => r.date).toSet(), DateTime.now());
});

int recordStreak(Set<String> dates, DateTime now) {
  var day = DateTime(now.year, now.month, now.day);
  if (!dates.contains(dateKey(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  var count = 0;
  while (dates.contains(dateKey(day))) {
    count++;
    day = day.subtract(const Duration(days: 1));
  }
  return count;
}

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
    _ref.invalidate(streakProvider);
    _ref.invalidate(quickFoodsProvider);
  }

  Future<void> add(FoodRecord record) async {
    await _repo.insert(record);
    _refresh();
  }

  Future<void> update(FoodRecord record) async {
    await _repo.update(record);
    _refresh();
  }

  Future<void> delete(int id) async {
    final photo = (await _repo.all())
        .where((r) => r.id == id)
        .firstOrNull
        ?.imagePath;
    await _repo.delete(id);
    _refresh();
    await _deletePhotoIfUnused(photo);
  }

  Future<void> deleteAll() async {
    final photos = {for (final r in await _repo.all()) r.imagePath};
    await _repo.deleteAll();
    _refresh();
    for (final p in photos) {
      await PhotoStore.delete(p);
    }
  }

  /// 같은 사진을 쓰는 다른 기록이 없을 때만 지운다 (한 사진에 음식 여러 개)
  Future<void> _deletePhotoIfUnused(String? photo) async {
    if (photo == null) return;
    if ((await _repo.all()).any((r) => r.imagePath == photo)) return;
    await PhotoStore.delete(photo);
  }
}

final mealActionsProvider = Provider<MealActions>(MealActions.new);

// ───────── 빠른 추가 (최근·자주 먹은 음식) ─────────

/// 이름별 가장 최근 기록. recent: 최근 먹은 순, frequent: 많이 먹은 순.
final quickFoodsProvider =
    FutureProvider<({List<FoodRecord> recent, List<FoodRecord> frequent})>((
      ref,
    ) async {
      final records = await ref.watch(mealRepositoryProvider).all();
      return quickFoods(records);
    });

({List<FoodRecord> recent, List<FoodRecord> frequent}) quickFoods(
  List<FoodRecord> records, {
  int limit = 12,
}) {
  final latest = <String, FoodRecord>{};
  final counts = <String, int>{};
  for (final r in records) {
    counts[r.foodName] = (counts[r.foodName] ?? 0) + 1;
    final prev = latest[r.foodName];
    if (prev == null || r.createdAt.isAfter(prev.createdAt)) {
      latest[r.foodName] = r;
    }
  }
  final recent = latest.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final frequent = latest.values.where((r) => counts[r.foodName]! >= 2).toList()
    ..sort((a, b) => counts[b.foodName]!.compareTo(counts[a.foodName]!));
  return (
    recent: recent.take(limit).toList(),
    frequent: frequent.take(limit).toList(),
  );
}

// ───────── 물·체중 ─────────

class WaterNotifier extends Notifier<int> {
  WaterNotifier(this.date);
  final String date;

  @override
  int build() => ref.watch(bodyLogRepositoryProvider).waterOn(date);

  Future<void> add(int ml) async {
    final next = (state + ml).clamp(0, 10000);
    await ref.read(bodyLogRepositoryProvider).setWater(date, next);
    state = next;
  }
}

/// 날짜(yyyy-MM-dd)별 마신 물 (ml)
final waterProvider = NotifierProvider.family<WaterNotifier, int, String>(
  WaterNotifier.new,
);

class WaterGoalNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(settingsRepositoryProvider).waterGoal;

  Future<void> set(int ml) async {
    await ref.read(settingsRepositoryProvider).setWaterGoal(ml);
    state = ml;
  }
}

final waterGoalProvider = NotifierProvider<WaterGoalNotifier, int>(
  WaterGoalNotifier.new,
);

class WeightsNotifier extends Notifier<List<(String, double)>> {
  @override
  List<(String, double)> build() =>
      ref.watch(bodyLogRepositoryProvider).weights();

  BodyLogRepository get _repo => ref.read(bodyLogRepositoryProvider);

  Future<void> record(String date, double kg) async {
    await _repo.setWeight(date, kg);
    state = _repo.weights();
  }

  Future<void> remove(String date) async {
    await _repo.deleteWeight(date);
    state = _repo.weights();
  }
}

/// 체중 기록 (날짜 오름차순)
final weightsProvider =
    NotifierProvider<WeightsNotifier, List<(String, double)>>(
      WeightsNotifier.new,
    );

class TargetWeightNotifier extends Notifier<double?> {
  @override
  double? build() => ref.watch(settingsRepositoryProvider).targetWeight;

  Future<void> set(double? kg) async {
    await ref.read(settingsRepositoryProvider).setTargetWeight(kg);
    state = kg;
  }
}

final targetWeightProvider = NotifierProvider<TargetWeightNotifier, double?>(
  TargetWeightNotifier.new,
);

// ───────── 끼니 알림 ─────────

class RemindersNotifier extends Notifier<List<MealReminder>> {
  @override
  List<MealReminder> build() => ref.watch(settingsRepositoryProvider).reminders;

  /// 알림을 바꾸고 다시 예약한다. 처음 켤 때 권한을 묻고, 거절하면 false.
  Future<bool> change(MealReminder next) async {
    final service = ref.read(reminderServiceProvider);
    if (next.enabled && !state.any((r) => r.enabled)) {
      if (!await service.requestPermission()) return false;
    }
    final list = [
      for (final r in state) r.mealType == next.mealType ? next : r,
    ];
    await ref.read(settingsRepositoryProvider).setReminders(list);
    state = list;
    await service.apply(list);
    return true;
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, List<MealReminder>>(
      RemindersNotifier.new,
    );
