import 'package:flutter/material.dart';

/// 디자인 토큰. 기준 문서: docs/PRODUCT_DESIGN.md 7장.
///
/// 색은 라이트/다크 두 벌을 [AppPalette]로 정의하고, 화면에서는
/// `context.palette.brand`처럼 꺼내 쓴다. 고정 색(Colors.white 등)을
/// 화면 코드에 직접 쓰지 않는다.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.brandPressed,
    required this.brandSubtle,
    required this.onBrand,
    required this.bg,
    required this.surface,
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

  final Color brand;
  final Color brandPressed;
  final Color brandSubtle;
  final Color onBrand;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color carbs;
  final Color protein;
  final Color fat;
  final Color over;
  final Color warning;

  static const light = AppPalette(
    brand: Color(0xFF12B76A),
    brandPressed: Color(0xFF039855),
    brandSubtle: Color(0xFFECFDF3),
    onBrand: Color(0xFFFFFFFF),
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F3F5),
    border: Color(0xFFE5E7EB),
    text1: Color(0xFF111827),
    text2: Color(0xFF6B7280),
    text3: Color(0xFF9CA3AF),
    carbs: Color(0xFF3B82F6),
    protein: Color(0xFFF43F5E),
    fat: Color(0xFFF59E0B),
    over: Color(0xFFEF4444),
    warning: Color(0xFFF79009),
  );

  static const dark = AppPalette(
    brand: Color(0xFF32D583),
    brandPressed: Color(0xFF6CE9A6),
    brandSubtle: Color(0xFF0B2E1F),
    onBrand: Color(0xFF052E1A),
    bg: Color(0xFF0E0F11),
    surface: Color(0xFF17191C),
    surfaceAlt: Color(0xFF202327),
    border: Color(0xFF2A2D31),
    text1: Color(0xFFF3F4F6),
    text2: Color(0xFF9CA3AF),
    text3: Color(0xFF6B7280),
    carbs: Color(0xFF60A5FA),
    protein: Color(0xFFFB7185),
    fat: Color(0xFFFBBF24),
    over: Color(0xFFF87171),
    warning: Color(0xFFFDB022),
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

/// 로고와 몰입형 화면(웰컴, 촬영)에 쓰는 브랜드 고정색. 테마와 무관하다.
abstract final class AppBrand {
  static const ink = Color(0xFF0E0F11);
  static const inkTop = Color(0xFF1C2026);
  static const neon = Color(0xFF6CF5B4);
  static const green = Color(0xFF12B76A);
  static const spark = Color(0xFFFFD84D);

  /// 로고 배경과 같은 어두운 그라데이션
  static const inkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkTop, ink],
  );

  /// 뷰파인더·강조 버튼에 쓰는 초록 그라데이션
  static const neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neon, green],
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
  static const chip = 8.0;
  static const control = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
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
