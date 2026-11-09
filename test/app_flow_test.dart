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
import 'package:snap_cal/data/repositories/settings_repository.dart';
import 'package:snap_cal/data/services/reminder_service.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs, {
  List<dynamic> overrides = const [],
}) async {
  // 아이폰 크기 화면
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      ...overrides.cast(),
    ],
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

/// [finder]가 화면 가운데 오도록 내린다 (아래쪽 탭 바에 가리지 않게)
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

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
    expect(find.text('1일 연속'), findsOneWidget);
    await scrollTo(tester, find.text('비빔밥'));
    expect(find.text('비빔밥'), findsOneWidget);

    await tester.drag(find.text('비빔밥'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('비빔밥'), findsNothing);
    expect(c.read(mealRepositoryProvider).all(), completion(isEmpty));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('2,000'), findsWidgets); // 다시 위로 올리면 남은 칼로리가 목표 그대로
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

  testWidgets('검색해서 추가: 초성 검색 → 2인분 → 아침에 기록', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await scrollTo(tester, find.text('검색해서 추가').first);
    await tester.tap(find.text('검색해서 추가').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ㄱㅊㅉㄱ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('김치찌개').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('아침에 추가'));
    await tester.pumpAndSettle();

    final saved = await c.read(mealRepositoryProvider).all();
    expect(saved.single.foodName, '김치찌개');
    expect(saved.single.calories, 500);
    expect(saved.single.servings, 2);
    expect(saved.single.mealType, 'breakfast');
    expect(find.text('오늘의 식사'), findsOneWidget);
  });

  testWidgets('기록을 눌러 양을 반으로 바꾼다', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await c.read(mealActionsProvider).add(lunch('비빔밥', 600));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('비빔밥'));
    await tester.tap(find.text('비빔밥'));
    await tester.pumpAndSettle();
    expect(find.text('기록 수정'), findsOneWidget);
    await tester.tap(find.text('0.5'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final r = (await c.read(mealRepositoryProvider).all()).single;
    expect(r.calories, 300);
    expect(r.servings, 0.5);
  });

  testWidgets('물 한 잔씩 추가', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await tester.scrollUntilVisible(
      find.byTooltip('물 한 잔 추가'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('물 한 잔 추가'));
    await tester.tap(find.byTooltip('물 한 잔 추가'));
    await tester.pumpAndSettle();
    expect(c.read(waterProvider(dateKey(DateTime.now()))), 500);
    expect(find.textContaining('500', findRichText: true), findsWidgets);
  });

  testWidgets('체중 기록', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await tester.tap(find.text('리포트'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('오늘 체중 기록'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('오늘 체중 기록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '64.5');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(c.read(weightsProvider).single.$2, 64.5);
    expect(find.text('64.5'), findsOneWidget);
  });

  testWidgets('끼니 알림 켜기: 권한을 묻고 예약한다', (tester) async {
    final fake = FakeReminders();
    final c = await pumpApp(
      tester,
      {'onboarded': true},
      overrides: [reminderServiceProvider.overrideWithValue(fake)],
    );
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Switch).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(fake.asked, 1);
    expect(fake.applied.last.first.enabled, isTrue);
    expect(c.read(remindersProvider).first.enabled, isTrue);
  });

  testWidgets('알림 권한을 거절하면 켜지지 않는다', (tester) async {
    final fake = FakeReminders(granted: false);
    final c = await pumpApp(
      tester,
      {'onboarded': true},
      overrides: [reminderServiceProvider.overrideWithValue(fake)],
    );
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Switch).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(c.read(remindersProvider).first.enabled, isFalse);
    expect(fake.applied, isEmpty);
    expect(find.textContaining('알림 권한이 꺼져 있어요'), findsOneWidget);
  });
}

class FakeReminders implements ReminderService {
  FakeReminders({this.granted = true});
  final bool granted;
  int asked = 0;
  final applied = <List<MealReminder>>[];

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted;
  }

  @override
  Future<void> apply(List<MealReminder> reminders) async =>
      applied.add(reminders);
}
