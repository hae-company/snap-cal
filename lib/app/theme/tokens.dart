import 'package:flutter/material.dart';

/// 디자인 토큰. 기준 문서: docs/PRODUCT_DESIGN.md 7장.
///
/// 방향: 흰 배경, 테두리 없는 연회색 카드, 둥근 모서리, 산뜻한 주황.
/// 색은 라이트/다크 두 벌을 [AppPalette]로 정의하고, 화면에서는
/// `context.palette.brand`처럼 꺼내 쓴다.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.brandPressed,
    required this.brandSubtle,
    required this.onBrand,
    required this.bg,
    required this.surface,
    required this.card,
    required this.surfaceAlt,
    required this.border,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.over,
    required this.warning,
  });

  /// 메인 주황
  final Color brand;
  final Color brandPressed;

  /// 연한 주황 배경 (선택 상태, 칩)
  final Color brandSubtle;
  final Color onBrand;

  /// 화면 배경
  final Color bg;

  /// 시트·대화상자·하단 탭처럼 떠 있는 면
  final Color surface;

  /// 카드 채움색 (테두리 없음)
  final Color card;

  /// 입력칸, 진행 막대 바탕
  final Color surfaceAlt;
  final Color border;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color carbs;
  final Color protein;
  final Color fat;

  /// 목표 초과 (주황과 구분되는 빨강)
  final Color over;
  final Color warning;

  static const light = AppPalette(
    brand: Color(0xFFFF7A2F),
    brandPressed: Color(0xFFE8601A),
    brandSubtle: Color(0xFFFFF1E8),
    onBrand: Color(0xFFFFFFFF),
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF7F7F8),
    surfaceAlt: Color(0xFFEDEEF0),
    border: Color(0xFFEAEBEE),
    text1: Color(0xFF212124),
    text2: Color(0xFF868B94),
    text3: Color(0xFFB0B3BA),
    carbs: Color(0xFF4C9AFF),
    protein: Color(0xFFFF5A7A),
    fat: Color(0xFFFFB020),
    over: Color(0xFFF04452),
    warning: Color(0xFFF5A524),
  );

  static const dark = AppPalette(
    brand: Color(0xFFFF8A47),
    brandPressed: Color(0xFFFFA36B),
    brandSubtle: Color(0xFF3A2215),
    onBrand: Color(0xFFFFFFFF),
    bg: Color(0xFF121214),
    surface: Color(0xFF1C1C1F),
    card: Color(0xFF1C1C1F),
    surfaceAlt: Color(0xFF2A2A2E),
    border: Color(0xFF2E2E33),
    text1: Color(0xFFF2F2F3),
    text2: Color(0xFF9A9AA2),
    text3: Color(0xFF6B6B73),
    carbs: Color(0xFF6AABFF),
    protein: Color(0xFFFF7A93),
    fat: Color(0xFFFFC14D),
    over: Color(0xFFFF6B75),
    warning: Color(0xFFFFC14D),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brand: l(brand, other.brand),
      brandPressed: l(brandPressed, other.brandPressed),
      brandSubtle: l(brandSubtle, other.brandSubtle),
      onBrand: l(onBrand, other.onBrand),
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text1: l(text1, other.text1),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      carbs: l(carbs, other.carbs),
      protein: l(protein, other.protein),
      fat: l(fat, other.fat),
      over: l(over, other.over),
      warning: l(warning, other.warning),
    );
  }
}

/// 로고와 같은 브랜드 고정색. 테마(라이트/다크)와 무관하게 같은 주황.
abstract final class AppBrand {
  static const orange = Color(0xFFFF7A2F);
  static const orangeLight = Color(0xFFFF9A52);
  static const orangeDeep = Color(0xFFFF6A1F);

  /// 반짝이 노랑
  static const spark = Color(0xFFFFD84D);

  /// 볼터치 분홍 (로고 얼굴)
  static const blush = Color(0xFFFFB38A);

  /// 로고 배경과 같은 주황 그라데이션 (강조 버튼, 목표 카드)
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orangeLight, orangeDeep],
  );
}

/// 글자 스타일. 색은 넣지 않는다 (테마 기본색 또는 `.copyWith(color:)`).
abstract final class AppText {
  static const _tabular = [FontFeature.tabularFigures()];

  /// 남은 칼로리처럼 크게 보여주는 숫자
  static const display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
    fontFeatures: _tabular,
  );
  static const title1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const title2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  static const headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 숫자가 바뀌어도 폭이 흔들리지 않게 할 때
  static TextStyle numeric(TextStyle s) => s.copyWith(fontFeatures: _tabular);
}

/// 간격 (4pt 단위)
abstract final class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// 화면 좌우 여백
  static const screen = 20.0;
}

/// 모서리 둥글기
abstract final class AppRadius {
  static const chip = 10.0;
  static const control = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

/// 모션 시간
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 300);
  static const ring = Duration(milliseconds: 700);
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
