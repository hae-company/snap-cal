import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_cal/app/app.dart';
import 'package:snap_cal/core/date_key.dart';
import 'package:snap_cal/data/ads/rewarded_ads.dart';
import 'package:snap_cal/data/billing/billing_models.dart';
import 'package:snap_cal/data/billing/billing_providers.dart';
import 'package:snap_cal/data/billing/billing_service.dart';
import 'package:snap_cal/data/billing/revenuecat_billing_service.dart';
import 'package:snap_cal/data/models/analysis_result.dart';
import 'package:snap_cal/data/providers.dart';
import 'package:snap_cal/data/repositories/food_analysis_repository.dart';

/// 가짜 결제 모드로 앱을 띄운다 ([mock]이 false면 결제 꺼짐 모드)
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Map<String, Object> prefs, {
  bool mock = true,
  List<dynamic> extra = const [],
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      if (mock)
        billingServiceProvider.overrideWithValue(MockBillingService(sp)),
      ...extra.cast(),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const CalorieSnapApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

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

  group('결제 로직', () {
    test('결제 모드 읽기: 모르는 값은 결제 꺼짐', () {
      expect(BillingMode.parse('revenuecat'), BillingMode.revenuecat);
      expect(BillingMode.parse(' MOCK '), BillingMode.mock);
      expect(BillingMode.parse(''), BillingMode.off);
      expect(BillingMode.off.enforcesPremium, isFalse);
    });

    test('가짜 결제: 연간은 7일 체험, 만료되면 무료로 돌아간다', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      var now = DateTime(2026, 11, 10);
      final billing = MockBillingService(sp, clock: () => now);

      expect((await billing.current()).premium, isFalse);
      final outcome = await billing.purchase(designPlans.first);
      expect(outcome, isA<PurchaseSuccess>());
      final e = await billing.current();
      expect(e.premium, isTrue);
      expect(e.inTrial, isTrue);
      expect(e.expiresAt, DateTime(2026, 11, 17));

      now = DateTime(2026, 11, 18);
      expect((await billing.current()).premium, isFalse);
    });

    test('RevenueCat 상품 정보 변환', () {
      expect(trialLengthDays('week', 1), 7);
      expect(trialLengthDays('day', 3), 3);
      expect(trialLengthDays('unknown', 2), 0);
      expect(perMonth(39000, 'KRW'), '월 3,250원');
      expect(perMonth(0, 'KRW'), isNull);
    });
  });

  testWidgets('결제 꺼짐: 잠금 없이 모두 열리고, 페이월은 미리보기', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true}, mock: false);
    expect(c.read(accessLevelProvider), AccessLevel.open);
    expect(c.read(remainingFreeAnalysesProvider), isNull);

    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    expect(find.text('프리미엄 (출시 예정)'), findsOneWidget);
    await tester.tap(find.text('미리보기'));
    await tester.pumpAndSettle();
    expect(find.text('출시 준비 중'), findsOneWidget);
    await tester.tap(find.text('출시 준비 중'));
    await tester.pumpAndSettle();
    expect(find.textContaining('결제는 출시와 함께 열려요'), findsWidgets);
  });

  testWidgets('무료 체험 3회를 다 쓰면 촬영 전에 페이월이 뜬다', (tester) async {
    final c = await pumpApp(tester, {
      'onboarded': true,
      'free_analyses_used': 3,
    });
    expect(c.read(remainingFreeAnalysesProvider), 0);

    await tester.tap(find.bySemanticsLabel('음식 촬영'));
    await tester.pumpAndSettle();
    expect(find.text('무료 분석을 모두 썼어요 · 사진과 함께 직접 기록할 수 있어요'), findsOneWidget);

    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();
    expect(find.text('칼로리스냅 프리미엄'), findsOneWidget);
    expect(find.textContaining('AI 사진 분석 무제한은(는) 프리미엄'), findsOneWidget);

    // 7일 무료 체험 시작 → 프리미엄, 남은 횟수 표시가 사라진다
    await tester.tap(find.text('7일 무료로 시작하기'));
    await tester.pumpAndSettle();
    expect(c.read(accessLevelProvider), AccessLevel.premium);
    expect(c.read(remainingFreeAnalysesProvider), isNull);
  });

  testWidgets('체중 그래프는 무료 사용자에게 잠겨 있고, 구독하면 열린다', (tester) async {
    final c = await pumpApp(tester, {
      'onboarded': true,
      'weight_log': '{"2026-11-01": 66.0, "${dateKey(DateTime.now())}": 65.2}',
    });
    await tester.tap(find.text('리포트'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('프리미엄으로 보기'));
    await tester.tap(find.text('프리미엄으로 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('월간'));
    await tester.pumpAndSettle();
    expect(find.text('월간 구독 시작하기'), findsOneWidget);
    await tester.tap(find.text('월간 구독 시작하기'));
    await tester.pumpAndSettle();

    expect(c.read(accessLevelProvider), AccessLevel.premium);
    expect(find.text('프리미엄으로 보기'), findsNothing);
  });

  testWidgets('MY: 구독 상태 표시와 구매 복원', (tester) async {
    final c = await pumpApp(tester, {'onboarded': true});
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    expect(find.text('무료 이용 중'), findsOneWidget);

    await tester.tap(find.text('구매 복원'));
    await tester.pumpAndSettle();
    expect(find.text('복원할 구독이 없어요'), findsOneWidget);

    await c.read(billingServiceProvider).purchase(designPlans.first);
    await tester.pumpAndSettle();
    expect(find.text('프리미엄 무료 체험 중'), findsOneWidget);
    expect(find.text('구독 관리'), findsOneWidget);
  });

  testWidgets('결제가 켜져 있으면 온보딩 끝에 페이월, 닫아도 앱으로 들어간다', (tester) async {
    final c = await pumpApp(tester, {});
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('여성'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('칼로리스냅 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('칼로리스냅 프리미엄'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(c.read(onboardedProvider), isTrue);
    expect(find.text('오늘의 식사'), findsOneWidget);
  });

  testWidgets('무료 분석을 다 쓰면: 사진은 찍고 AI 없이 검색해서 기록, 사진이 기록에 붙는다', (tester) async {
    ImagePickerPlatform.instance = FakePicker('/tmp/snapcal_test_meal.jpg');
    final c = await pumpApp(tester, {
      'onboarded': true,
      'free_analyses_used': 3,
    });
    await tester.tap(find.bySemanticsLabel('음식 촬영'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI 없이 사진과 함께 직접 기록하기'));
    await tester.pumpAndSettle();
    expect(find.text('음식 추가'), findsOneWidget);
    expect(find.text('사진과 함께 기록해요'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ㄱㅊㅉㄱ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('김치찌개').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('에 추가'));
    await tester.pumpAndSettle();

    final saved = (await c.read(mealRepositoryProvider).all()).single;
    expect(saved.foodName, '김치찌개');
    expect(
      saved.imagePath,
      '/tmp/snapcal_test_meal.jpg',
    ); // 시험 환경엔 보관 폴더가 없어 원래 경로
    expect(c.read(freeAnalysesUsedProvider), 3); // AI를 안 썼으니 횟수 그대로
  });

  testWidgets('잠긴 기능의 페이월에는 "직접 기록" 버튼이 없다', (tester) async {
    await pumpApp(tester, {'onboarded': true});
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('프리미엄 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('칼로리스냅 프리미엄'), findsOneWidget);
    expect(find.text('AI 없이 사진과 함께 직접 기록하기'), findsNothing);
  });

  group('광고 보상', () {
    test('하루 2회까지만 받고, 체험을 먼저 쓴 뒤 보너스를 쓴다', () async {
      SharedPreferences.setMockInitialValues({'free_analyses_used': 3});
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          billingServiceProvider.overrideWithValue(MockBillingService(sp)),
          rewardedAdsProvider.overrideWithValue(FakeRewardedAds()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(entitlementProvider.future);

      expect(c.read(remainingFreeAnalysesProvider), 0);
      expect(c.read(canWatchAdProvider), isTrue);
      expect(await c.read(adRewardsProvider.notifier).grant(), isTrue);
      expect(await c.read(adRewardsProvider.notifier).grant(), isTrue);
      expect(
        await c.read(adRewardsProvider.notifier).grant(),
        isFalse,
      ); // 하루 한도
      expect(c.read(remainingFreeAnalysesProvider), 2);
      expect(c.read(canWatchAdProvider), isFalse);

      await c.read(freeAnalysesUsedProvider.notifier).recordUse();
      expect(c.read(remainingFreeAnalysesProvider), 1);
      expect(c.read(freeAnalysesUsedProvider), 3); // 체험 횟수는 그대로, 보너스만 줄었다
    });
  });

  testWidgets('체험을 다 쓰면 광고를 보고 1회 받아 바로 분석한다', (tester) async {
    ImagePickerPlatform.instance = FakePicker('/tmp/snapcal_ad_meal.jpg');
    final ads = FakeRewardedAds();
    final c = await pumpApp(
      tester,
      {'onboarded': true, 'free_analyses_used': 3},
      extra: [
        rewardedAdsProvider.overrideWithValue(ads),
        foodAnalysisRepositoryProvider.overrideWithValue(FakeAnalysis()),
      ],
    );
    await tester.tap(find.bySemanticsLabel('음식 촬영'));
    await tester.pumpAndSettle();
    expect(find.text('무료 분석을 모두 썼어요 · 광고 보고 1회 더 받기'), findsOneWidget);

    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('광고 보고 1회 더 받기 (오늘 0/2)'));
    // 분석 중 스캔 애니메이션이 계속 돌아서 시간을 직접 흘려보낸다
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(ads.shown, 1);
    expect(find.text('김치찌개'), findsOneWidget); // 결과 화면
    expect(c.read(adRewardsProvider).today, 1);
    expect(c.read(adRewardsProvider).bonus, 0); // 받은 1회를 바로 씀
  });

  testWidgets('광고를 중간에 닫으면 보상이 없다', (tester) async {
    final ads = FakeRewardedAds(outcome: RewardOutcome.cancelled);
    final c = await pumpApp(
      tester,
      {'onboarded': true, 'free_analyses_used': 3},
      extra: [rewardedAdsProvider.overrideWithValue(ads)],
    );
    await tester.tap(find.bySemanticsLabel('음식 촬영'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('광고 보고 1회 더 받기 (오늘 0/2)'));
    await tester.pumpAndSettle();

    expect(find.text('광고를 끝까지 봐야 1회를 받을 수 있어요'), findsOneWidget);
    expect(c.read(adRewardsProvider).bonus, 0);
    expect(find.text('칼로리스냅 프리미엄'), findsOneWidget); // 페이월 그대로
  });

  testWidgets('오늘 한도를 다 쓰거나 광고가 꺼져 있으면 광고 버튼이 없다', (tester) async {
    await pumpApp(
      tester,
      {
        'onboarded': true,
        'free_analyses_used': 3,
        'ad_reward_day': dateKey(DateTime.now()),
        'ad_reward_count': 2,
      },
      extra: [rewardedAdsProvider.overrideWithValue(FakeRewardedAds())],
    );
    await tester.tap(find.bySemanticsLabel('음식 촬영'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범'));
    await tester.pumpAndSettle();
    expect(find.textContaining('광고 보고'), findsNothing);
    expect(find.text('AI 없이 사진과 함께 직접 기록하기'), findsOneWidget);
  });
}

class FakeAnalysis implements FoodAnalysisRepository {
  @override
  Future<AnalysisResult> analyze(_) async => AnalysisResult(
    foodName: '김치찌개',
    calories: 250,
    carbs: 12,
    protein: 18,
    fat: 14,
    confidence: 'high',
    description: '',
  );
}

/// 고르면 항상 같은 사진을 돌려주는 가짜 사진 선택기
class FakePicker extends ImagePickerPlatform {
  FakePicker(this.path);
  final String path;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(Uint8List.fromList(const [1, 2, 3]), path: path);
}
