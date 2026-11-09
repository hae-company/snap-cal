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
import 'package:snap_cal/features/log/day_detail_sheet.dart';

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

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('첫 실행: 온보딩을 마치면 목표가 저장되고 캘린더로 간다', (tester) async {
    final c = await pumpApp(tester, {});
    expect(find.text('성별을 알려주세요'), findsOneWidget);

    await tester.tap(find.text('남성'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('2245 kcal'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('SnapCal'), findsOneWidget);
    expect(c.read(goalsProvider).kcal, 2245);
    expect(c.read(onboardedProvider), isTrue);
  });

  testWidgets('탭 이동과 다크 테마 전환', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});

    await tester.tap(find.text('통계'));
    await tester.pumpAndSettle();
    expect(find.text('이번 주 통계'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('다크'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(c.read(themeModeProvider), ThemeMode.dark);
    final ctx = tester.element(find.text('테마'));
    expect(ctx.palette.bg, AppPalette.dark.bg);
  });

  testWidgets('하루 상세: 기록을 지우면 시트에서 바로 사라진다', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    final today = DateTime.now();
    await c
        .read(mealActionsProvider)
        .add(
          FoodRecord(
            date: dateKey(today),
            mealType: 'lunch',
            foodName: '비빔밥',
            calories: 600,
            carbs: 90,
            protein: 20,
            fat: 15,
          ),
        );

    showDayDetailSheet(tester.element(find.text('SnapCal')), today);
    await tester.pumpAndSettle();
    expect(find.text('비빔밥'), findsOneWidget);
    expect(find.text('600 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('비빔밥'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('이 날은 기록이 없어요'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('이 날은 기록이 없어요'), findsOneWidget);
  });

  testWidgets('캘린더: 기록이 없는 오늘도 날짜 원 크기가 같다', (tester) async {
    await pumpApp(tester, {'onboarded': true});
    final today = DateTime.now().day.toString();
    final circle = find
        .ancestor(of: find.text(today), matching: find.byType(Container))
        .first;
    expect(tester.getSize(circle), const Size(48, 48));
  });
}
