import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_cal/app/app.dart';
import 'package:snap_cal/app/theme/tokens.dart';
import 'package:snap_cal/core/date_key.dart';
import 'package:snap_cal/data/models/food_record.dart';
import 'package:snap_cal/data/providers.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs,
) async {
  // 아이폰 크기 화면
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SnapCalApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

FoodRecord lunch(String name, int kcal) => FoodRecord(
  date: dateKey(DateTime.now()),
  mealType: 'lunch',
  foodName: name,
  calories: kcal,
  carbs: 90,
  protein: 20,
  fat: 15,
);

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('첫 실행: 온보딩을 마치면 목표가 저장되고 오늘 화면으로 간다', (tester) async {
    final c = await pumpApp(tester, {});
    expect(find.text('찍으면 끝.\n한식도 정확하게.'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('성별을 알려주세요'), findsOneWidget);

    // 성별을 고르기 전에는 다음으로 갈 수 없다
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('성별을 알려주세요'), findsOneWidget);

    await tester.tap(find.text('남성'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    expect(find.text('2,245'), findsOneWidget);

    await tester.tap(find.text('스냅칼 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 식사'), findsOneWidget);
    expect(c.read(goalsProvider).kcal, 2245);
    expect(c.read(onboardedProvider), isTrue);
  });

  testWidgets('오늘 화면: 남은 칼로리와 기록이 보이고, 밀어서 지울 수 있다', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true, 'daily_goal': 2000});
    await c.read(mealActionsProvider).add(lunch('비빔밥', 600));
    await tester.pumpAndSettle();

    expect(find.text('1,400'), findsOneWidget); // 남은 칼로리
    expect(find.text('비빔밥'), findsOneWidget);
    expect(find.text('1일 연속'), findsOneWidget);

    await tester.drag(find.text('비빔밥'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('비빔밥'), findsNothing);
    expect(find.text('2,000'), findsWidgets);
  });

  testWidgets('탭 이동과 다크 테마 전환', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});

    await tester.tap(find.text('리포트'));
    await tester.pumpAndSettle();
    expect(find.text('일별 칼로리'), findsOneWidget);

    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('다크'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(c.read(themeModeProvider), ThemeMode.dark);
    expect(tester.element(find.text('다크')).palette.bg, AppPalette.dark.bg);
  });

  testWidgets('기록 화면: 날짜 원 크기가 일정하고, 고른 날의 기록이 아래에 보인다', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await c.read(mealActionsProvider).add(lunch('김치찌개', 700));

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    final today = DateTime.now().day.toString();
    final circle = find
        .ancestor(
          of: find.text(today),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    expect(tester.getSize(circle), const Size(40, 40));

    await tester.scrollUntilVisible(
      find.text('김치찌개'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('김치찌개'), findsOneWidget);
  });

  testWidgets('목표 수정 시트', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1800');
    await tester.tap(find.text('칼로리에 맞춰 탄단지 자동 계산'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(c.read(goalsProvider).kcal, 1800);
    expect(c.read(goalsProvider).carbsG, 225);
  });
}
