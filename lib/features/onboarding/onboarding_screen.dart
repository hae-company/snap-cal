import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/nutrition_calc.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/calorie_ring.dart';

/// 첫 실행: 환영 → 성별 → 신체 정보 → 활동량 → 맞춤 목표. 완료하면 라우터가 홈으로 보낸다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _lastStep = 4;

  int _step = 0;
  String _gender = '';
  int _age = 25;
  double _weight = 65;
  double _height = 170;
  int _activity = 1;
  bool _saving = false;

  int get _tdee => calcTdee(
    male: _gender == 'male',
    age: _age,
    heightCm: _height,
    weightKg: _weight,
    activityIndex: _activity,
  );

  bool get _canProceed => _step != 1 || _gender.isNotEmpty;

  void _next() {
    HapticFeedback.selectionClick();
    if (_step < _lastStep) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(goalsProvider.notifier).save(NutritionGoals.fromKcal(_tdee));
    await ref.read(onboardedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _Welcome(onStart: _next);

    final p = context.palette;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xxs,
                AppSpace.xxs,
                AppSpace.screen,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saving ? null : () => setState(() => _step--),
                    tooltip: '이전',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: AppSpace.xxs),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: _step / _lastStep),
                        duration: AppMotion.page,
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: p.surfaceAlt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    '$_step/$_lastStep',
                    style: AppText.numeric(
                      AppText.caption,
                    ).copyWith(color: p.text3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.page,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    AppSpace.xl,
                    AppSpace.xl,
                    AppSpace.xl,
                  ),
                  child: switch (_step) {
                    1 => _genderStep(p),
                    2 => _bodyStep(p),
                    3 => _activityStep(p),
                    _ => _resultStep(p),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.xl,
                AppSpace.md,
              ),
              child: FilledButton(
                onPressed: !_canProceed || _saving ? null : _next,
                child: Text(_step < _lastStep ? '다음' : '스냅칼 시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(AppPalette p, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppText.title1.copyWith(fontSize: 28, letterSpacing: -0.5),
      ),
      const SizedBox(height: AppSpace.xs),
      Text(subtitle, style: AppText.body.copyWith(color: p.text2)),
    ],
  );

  Widget _genderStep(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '성별을 알려주세요', '기초대사량 계산에 필요해요'),
        const SizedBox(height: AppSpace.xxl),
        Row(
          children: [
            Expanded(
              child: _genderCard(p, 'male', Icons.male_rounded, '남성', p.carbs),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _genderCard(
                p,
                'female',
                Icons.female_rounded,
                '여성',
                p.protein,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderCard(
    AppPalette p,
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    final selected = _gender == value;
    return _SelectableCard(
      selected: selected,
      onTap: () => setState(() => _gender = value),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            label,
            style: AppText.headline.copyWith(
              color: selected ? p.text1 : p.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyStep(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '몸 상태를 알려주세요', '하루 필요한 칼로리를 계산해요'),
        const SizedBox(height: AppSpace.xxl),
        _slider(p, '나이', _age.toDouble(), '세', 10, 80, (v) => _age = v.round()),
        const SizedBox(height: AppSpace.sm),
        _slider(p, '키', _height, 'cm', 130, 210, (v) => _height = v),
        const SizedBox(height: AppSpace.sm),
        _slider(p, '몸무게', _weight, 'kg', 30, 150, (v) => _weight = v),
      ],
    );
  }

  Widget _slider(
    AppPalette p,
    String label,
    double current,
    String unit,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final display = '${current.round()}';
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: AppText.label.copyWith(color: p.text2)),
              const Spacer(),
              Text(
                display,
                style: AppText.numeric(AppText.title1).copyWith(color: p.text1),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: AppText.caption.copyWith(color: p.text2),
                ),
              ),
            ],
          ),
          Slider(
            value: current,
            min: min,
            max: max,
            semanticFormatterCallback: (_) => '$display$unit',
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ],
      ),
    );
  }

  Widget _activityStep(AppPalette p) {
    const icons = [
      Icons.weekend_rounded,
      Icons.directions_walk_rounded,
      Icons.directions_run_rounded,
      Icons.fitness_center_rounded,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '평소 얼마나 움직이세요?', '활동량에 따라 목표 칼로리가 달라져요'),
        const SizedBox(height: AppSpace.xxl),
        for (var i = 0; i < ActivityLevel.all.length; i++) ...[
          _SelectableCard(
            selected: _activity == i,
            onTap: () => setState(() => _activity = i),
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _activity == i ? p.brand : p.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(
                    icons[i],
                    color: _activity == i ? p.onBrand : p.text2,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ActivityLevel.all[i].label,
                        style: AppText.headline.copyWith(fontSize: 16),
                      ),
                      Text(
                        ActivityLevel.all[i].description,
                        style: AppText.caption.copyWith(color: p.text2),
                      ),
                    ],
                  ),
                ),
                if (_activity == i)
                  Icon(Icons.check_circle_rounded, color: p.brand),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }

  Widget _resultStep(AppPalette p) {
    final g = NutritionGoals.fromKcal(_tdee);
    Widget macro(String label, int grams, String pct, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: c.withAlpha(24),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.micro.copyWith(fontSize: 12, color: p.text2),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              '${grams}g',
              style: AppText.numeric(AppText.title2).copyWith(color: c),
            ),
            Text(pct, style: AppText.micro.copyWith(color: p.text3)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '맞춤 목표가 준비됐어요', '이 목표에 맞춰 남은 칼로리를 알려드릴게요'),
        const SizedBox(height: AppSpace.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
          decoration: BoxDecoration(
            gradient: AppBrand.inkGradient,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          child: Column(
            children: [
              Text(
                '하루 권장 칼로리',
                style: AppText.label.copyWith(color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: AppSpace.xs),
              ShaderMask(
                shaderCallback: (r) => AppBrand.neonGradient.createShader(r),
                child: Text(
                  formatKcal(g.kcal),
                  style: AppText.display.copyWith(
                    fontSize: 56,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              Text(
                'kcal',
                style: AppText.headline.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            macro('탄수화물', g.carbsG, '50%', p.carbs),
            const SizedBox(width: AppSpace.xs),
            macro('단백질', g.proteinG, '30%', p.protein),
            const SizedBox(width: AppSpace.xs),
            macro('지방', g.fatG, '20%', p.fat),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          '목표는 MY에서 언제든 바꿀 수 있어요',
          style: AppText.caption.copyWith(color: p.text3),
        ),
      ],
    );
  }
}

/// 첫 화면. 로고와 같은 어두운 브랜드 화면.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    Widget feature(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1A6CF5B4),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: AppBrand.neon, size: 22),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.headline.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  body,
                  style: AppText.caption.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Theme(
      data: AppTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppBrand.ink,
          body: Stack(
            children: [
              Positioned(
                top: -120,
                left: -80,
                right: -80,
                child: Container(
                  height: 420,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x4012B76A), Color(0x0012B76A)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    AppSpace.xxxl,
                    AppSpace.xl,
                    AppSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LogoTile(size: 88),
                      const SizedBox(height: AppSpace.xl),
                      Text(
                        '찍으면 끝.\n한식도 정확하게.',
                        style: AppText.title1.copyWith(
                          fontSize: 34,
                          height: 1.25,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        '사진 한 장으로 칼로리와 탄단지를 기록하세요',
                        style: AppText.body.copyWith(
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const Spacer(),
                      feature(
                        Icons.photo_camera_rounded,
                        '사진 한 장이면 끝',
                        '검색 없이 찍기만 하면 AI가 분석해요',
                      ),
                      feature(
                        Icons.ramen_dining_rounded,
                        '한식에 강해요',
                        '찌개, 반찬, 한 상 차림도 1인분 기준으로',
                      ),
                      feature(
                        Icons.donut_large_rounded,
                        '남은 칼로리 한눈에',
                        '목표까지 얼마나 남았는지 바로 보여요',
                      ),
                      const SizedBox(height: AppSpace.lg),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppBrand.neonGradient,
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                          ),
                          child: FilledButton(
                            onPressed: onStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppBrand.ink,
                            ),
                            child: const Text('시작하기'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.padding,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? p.brandSubtle : p.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? p.brand : p.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
