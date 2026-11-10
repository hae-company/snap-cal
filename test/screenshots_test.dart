// 디자인 검수용 화면 캡처. 평소 테스트에서는 건너뛴다.
//
//   flutter test test/screenshots_test.dart --dart-define=SHOT_DIR=/절대/경로
//
// 실제 폰트(Pretendard, Material 아이콘)를 읽어 iPhone 크기로 각 화면을 PNG로 저장한다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_cal/app/app.dart';
import 'package:snap_cal/app/router.dart';
import 'package:snap_cal/core/date_key.dart';
import 'package:snap_cal/data/models/analysis_result.dart';
import 'package:snap_cal/data/models/food_record.dart';
import 'package:snap_cal/data/ads/rewarded_ads.dart';
import 'package:snap_cal/data/billing/billing_providers.dart';
import 'package:snap_cal/data/billing/billing_service.dart';
import 'package:snap_cal/data/providers.dart';
import 'package:snap_cal/features/capture/result_screen.dart';

const shotDir = String.fromEnvironment('SHOT_DIR');

Future<void> loadFonts() async {
  final pretendard = FontLoader('Pretendard');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    pretendard.addFont(rootBundle.load('assets/fonts/Pretendard-$w.otf'));
  }
  await pretendard.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

List<FoodRecord> seed() {
  final now = DateTime.now();
  final today = dateKey(now);
  FoodRecord r(
    String date,
    String meal,
    String name,
    int kcal,
    int c,
    int p,
    int f, [
    int hour = 12,
  ]) => FoodRecord(
    date: date,
    mealType: meal,
    foodName: name,
    calories: kcal,
    carbs: c,
    protein: p,
    fat: f,
    createdAt: DateTime(now.year, now.month, now.day, hour),
  );
  final monday = mondayOf(now);
  final week = [
    for (var i = 0; i < 7; i++)
      if (monday
          .add(Duration(days: i))
          .isBefore(DateTime(now.year, now.month, now.day)))
        r(
          dateKey(monday.add(Duration(days: i))),
          'dinner',
          ['제육볶음 정식', '후라이드 치킨', '비빔밥', '삼겹살', '김밥'][i % 5],
          [1900, 2600, 1650, 2250, 1400][i % 5],
          220,
          90,
          60,
          19,
        ),
  ];
  return [
    ...week,
    r(
      dateKey(now.subtract(const Duration(days: 10))),
      'lunch',
      '김치찌개 정식',
      2000,
      250,
      80,
      60,
    ),
    r(today, 'breakfast', '그릭요거트 & 그래놀라', 320, 42, 18, 9, 8),
    r(today, 'breakfast', '아메리카노', 5, 0, 0, 0, 8),
    r(today, 'lunch', '김치찌개 정식', 760, 92, 34, 24, 12),
  ];
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
    await loadFonts();
  });

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    // 이미지(로고) 디코딩이 끝날 시간을 준다
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 900));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$shotDir/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final dark in [false, true]) {
    final suffix = dark ? 'dark' : 'light';

    testWidgets('screens $suffix', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 162, bottom: 102);
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'theme_mode': dark ? 'dark' : 'light',
        'daily_goal': 2100,
        'carbs_goal': 262,
        'protein_goal': 158,
        'fat_goal': 47,
      });
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          billingServiceProvider.overrideWithValue(DisabledBillingService()),
          rewardedAdsProvider.overrideWithValue(DisabledRewardedAds()),
        ],
      );
      addTearDown(c.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: UncontrolledProviderScope(
            container: c,
            child: const CalorieSnapApp(),
          ),
        ),
      );

      // 온보딩
      await shoot(tester, key, '01_welcome_$suffix');
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('여성'));
      await shoot(tester, key, '02_gender_$suffix');
      await tester.tap(find.text('다음'));
      await shoot(tester, key, '03_body_$suffix');
      await tester.tap(find.text('다음'));
      await shoot(tester, key, '04_activity_$suffix');
      await tester.tap(find.text('다음'));
      await shoot(tester, key, '05_goal_$suffix');

      // 홈 이후 화면은 기록이 있는 상태로
      await c.read(onboardedProvider.notifier).complete();
      await c.read(goalsProvider.notifier).save(c.read(goalsProvider));
      await tester.runAsync(() async {
        for (final r in seed()) {
          await c.read(mealRepositoryProvider).insert(r);
        }
      });
      c.invalidate(mealsInRangeProvider);
      c.invalidate(topFoodsProvider);
      c.invalidate(streakProvider);
      c.invalidate(quickFoodsProvider);
      final today = dateKey(DateTime.now());
      await tester.runAsync(() async {
        await c.read(waterProvider(today).notifier).add(1250);
        for (final (i, kg) in [
          66.4,
          66.1,
          65.9,
          66.0,
          65.6,
          65.2,
          65.3,
          64.9,
        ].indexed) {
          await c
              .read(weightsProvider.notifier)
              .record(
                dateKey(DateTime.now().subtract(Duration(days: (7 - i) * 3))),
                kg,
              );
        }
        await c.read(targetWeightProvider.notifier).set(62);
      });
      final router = c.read(routerProvider);

      for (final (route, name) in [
        (Routes.today, '06_today'),
        (Routes.log, '07_log'),
        (Routes.report, '08_report'),
        (Routes.my, '09_my'),
      ]) {
        router.go(route);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await shoot(tester, key, '${name}_$suffix');
        // 아래쪽도 한 장 더
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await shoot(tester, key, '${name}b_$suffix');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      }

      // 검색해서 추가 (음식 목록 파일을 미리 읽어 둔다)
      await tester.runAsync(() => c.read(foodCatalogRepositoryProvider).all());
      router.push('${Routes.add}?meal=lunch');
      await shoot(tester, key, '12_add_$suffix');
      await tester.enterText(find.byType(TextField).first, 'ㅊㅋ');
      await shoot(tester, key, '13_search_$suffix');
      await tester.tap(find.text('양념치킨'));
      await shoot(tester, key, '14_portion_$suffix');
      Navigator.of(tester.element(find.text('양념치킨').last)).pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // 기록 수정 시트
      router.go(Routes.today);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('김치찌개 정식'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('김치찌개 정식'));
      await shoot(tester, key, '15_edit_$suffix');
      Navigator.of(tester.element(find.text('기록 수정'))).pop();
      await tester.pumpAndSettle();

      router.push(Routes.capture);
      await shoot(tester, key, '10_capture_$suffix');
      router.pop();
      await tester.pumpAndSettle();

      router.push(
        Routes.result,
        extra: ResultArgs(
          imagePath: '/nonexistent.jpg',
          result: AnalysisResult(
            foodName: '김치찌개 정식',
            calories: 620,
            totalCalories: 1240,
            servingInfo: '밥 1공기 + 찌개 1그릇 + 반찬 3종',
            carbs: 82,
            protein: 31,
            fat: 18,
            confidence: 'medium',
            description: '돼지고기 김치찌개와 쌀밥, 계란말이·김치·콩나물 반찬',
          ),
        ),
      );
      await shoot(tester, key, '11_result_$suffix');
    }, skip: shotDir.isEmpty);
  }
}
