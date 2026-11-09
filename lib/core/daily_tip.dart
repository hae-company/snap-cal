import 'nutrition_calc.dart';

enum TipKind { start, over, protein, water, almost, fat, good }

class DailyTip {
  const DailyTip(this.kind, this.title, this.body);
  final TipKind kind;
  final String title;
  final String body;
}

/// 오늘 먹은 양에 맞춘 한 줄 조언. 위에 있는 규칙일수록 우선한다.
DailyTip dailyTip({
  required DateTime now,
  required int recordCount,
  required int kcal,
  required int protein,
  required int fat,
  required NutritionGoals goals,
  required int waterMl,
  required int waterGoalMl,
}) {
  final h = now.hour;
  if (recordCount == 0) {
    return h < 11
        ? const DailyTip(
            TipKind.start,
            '아침을 기록해볼까요?',
            '아침 한 끼를 기록하면 하루 계획이 훨씬 쉬워져요.',
          )
        : const DailyTip(
            TipKind.start,
            '오늘 첫 끼를 기록해보세요',
            '사진 한 장이면 칼로리와 탄단지가 바로 계산돼요.',
          );
  }
  final remaining = goals.kcal - kcal;
  if (kcal > goals.kcal * 1.1) {
    return DailyTip(
      TipKind.over,
      '목표보다 ${-remaining} kcal 더 드셨어요',
      '괜찮아요. 남은 식사는 가볍게, 내일 다시 맞춰봐요.',
    );
  }
  if (h >= 15 && protein < goals.proteinG * 0.5) {
    return DailyTip(
      TipKind.protein,
      '단백질이 부족해요 ($protein / ${goals.proteinG}g)',
      '닭가슴살, 두부, 계란, 그릭요거트를 곁들여 보세요.',
    );
  }
  if (h >= 14 && waterGoalMl > 0 && waterMl < waterGoalMl * 0.4) {
    return DailyTip(
      TipKind.water,
      '물 한 잔 어때요?',
      '오늘 ${waterMl}ml 마셨어요. 목표는 ${waterGoalMl}ml예요.',
    );
  }
  if (fat > goals.fatG) {
    return DailyTip(TipKind.fat, '지방이 목표를 넘었어요', '튀김이나 크림 메뉴는 다음 끼니에 줄여봐요.');
  }
  if (remaining >= 0 && remaining < goals.kcal * 0.15) {
    return DailyTip(
      TipKind.almost,
      '목표까지 $remaining kcal 남았어요',
      '간식은 과일이나 견과류처럼 가볍게 골라보세요.',
    );
  }
  return DailyTip(TipKind.good, '잘하고 있어요!', '남은 $remaining kcal 안에서 맛있게 드세요.');
}
