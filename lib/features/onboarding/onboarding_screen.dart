import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/nutrition_calc.dart';
import '../../data/providers.dart';

/// 첫 실행 목표 설정. 완료하면 라우터가 홈으로 보낸다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _lastStep = 3;

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

  bool get _canProceed => _step != 0 || _gender.isNotEmpty;

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(goalsProvider.notifier).save(NutritionGoals.fromKcal(_tdee));
    await ref.read(onboardedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            children: [
              Row(
                children: List.generate(
                  _lastStep + 1,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _step ? p.brand : p.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: switch (_step) {
                    0 => _genderStep(p),
                    1 => _bodyStep(p),
                    2 => _activityStep(p),
                    _ => _resultStep(p),
                  },
                ),
              ),
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step--),
                        child: const Text('이전'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: !_canProceed || _saving
                          ? null
                          : () => _step < _lastStep
                                ? setState(() => _step++)
                                : _finish(),
                      child: Text(_step < _lastStep ? '다음' : '시작하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(AppPalette p, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppText.title1.copyWith(fontSize: 28)),
      const SizedBox(height: AppSpace.xs),
      Text(subtitle, style: AppText.body.copyWith(color: p.text2)),
    ],
  );

  Widget _genderStep(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '성별을 알려주세요', '정확한 칼로리 계산을 위해 필요해요'),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _genderCard(p, 'male', '👨', '남성')),
            const SizedBox(width: AppSpace.md),
            Expanded(child: _genderCard(p, 'female', '👩', '여성')),
          ],
        ),
      ],
    );
  }

  Widget _genderCard(AppPalette p, String value, String emoji, String label) {
    final selected = _gender == value;
    return _SelectableCard(
      selected: selected,
      onTap: () => setState(() => _gender = value),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpace.xs),
          Text(
            label,
            style: AppText.headline.copyWith(
              fontSize: 18,
              color: selected ? p.brand : p.text1,
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
        _heading(p, '신체 정보', '기초대사량 계산에 사용돼요'),
        const SizedBox(height: 40),
        _slider(
          p,
          '나이',
          '$_age세',
          _age.toDouble(),
          10,
          80,
          (v) => _age = v.round(),
        ),
        const SizedBox(height: AppSpace.xl),
        _slider(
          p,
          '키',
          '${_height.round()}cm',
          _height,
          130,
          210,
          (v) => _height = v,
        ),
        const SizedBox(height: AppSpace.xl),
        _slider(
          p,
          '몸무게',
          '${_weight.round()}kg',
          _weight,
          30,
          150,
          (v) => _weight = v,
        ),
      ],
    );
  }

  Widget _slider(
    AppPalette p,
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppText.headline.copyWith(fontSize: 16)),
            const Spacer(),
            Text(
              value,
              style: AppText.numeric(AppText.title2).copyWith(color: p.brand),
            ),
          ],
        ),
        Slider(
          value: current,
          min: min,
          max: max,
          semanticFormatterCallback: (_) => value,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Widget _activityStep(AppPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(p, '활동량은 어떤가요?', '일일 소비 칼로리를 계산해요'),
        const SizedBox(height: AppSpace.xxl),
        for (var i = 0; i < ActivityLevel.all.length; i++) ...[
          _activityCard(p, i),
          if (i < ActivityLevel.all.length - 1)
            const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }

  Widget _activityCard(AppPalette p, int index) {
    final selected = _activity == index;
    final a = ActivityLevel.all[index];
    return _SelectableCard(
      selected: selected,
      onTap: () => setState(() => _activity = index),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? p.brand : p.text3, width: 2),
              color: selected ? p.brand : Colors.transparent,
            ),
            child: selected
                ? Icon(Icons.check, size: 14, color: p.onBrand)
                : null,
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.label,
                style: AppText.headline.copyWith(
                  fontSize: 16,
                  color: selected ? p.brand : p.text1,
                ),
              ),
              Text(
                a.description,
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: p.text2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultStep(AppPalette p) {
    final goals = NutritionGoals.fromKcal(_tdee);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('맞춤 목표가\n설정되었어요!', style: AppText.title1.copyWith(fontSize: 28)),
        const SizedBox(height: AppSpace.xxl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            color: p.brandSubtle,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          child: Column(
            children: [
              Text(
                '일일 권장 칼로리',
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: p.text2,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                '${goals.kcal} kcal',
                style: AppText.display.copyWith(fontSize: 36, color: p.brand),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            _macro(p, '탄수화물', goals.carbsG, '50%', p.carbs),
            const SizedBox(width: AppSpace.sm),
            _macro(p, '단백질', goals.proteinG, '30%', p.protein),
            const SizedBox(width: AppSpace.sm),
            _macro(p, '지방', goals.fatG, '20%', p.fat),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          '설정에서 언제든 변경할 수 있어요',
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w400,
            color: p.text3,
          ),
        ),
      ],
    );
  }

  Widget _macro(
    AppPalette p,
    String label,
    int grams,
    String pct,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppText.micro.copyWith(fontSize: 12, color: color),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              '${grams}g',
              style: AppText.numeric(AppText.title2).copyWith(color: color),
            ),
            Text(
              pct,
              style: AppText.micro.copyWith(
                fontWeight: FontWeight.w500,
                color: color.withAlpha(170),
              ),
            ),
          ],
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
        onTap: onTap,
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
