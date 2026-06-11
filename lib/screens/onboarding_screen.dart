import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _gender = '';
  int _age = 25;
  double _weight = 65;
  double _height = 170;
  int _activity = 1; // 0: 거의 안함, 1: 가벼운, 2: 보통, 3: 활발

  final _activities = [
    {'label': '거의 안 함', 'desc': '주로 앉아서 생활', 'factor': 1.2},
    {'label': '가벼운 활동', 'desc': '주 1~3회 운동', 'factor': 1.375},
    {'label': '보통 활동', 'desc': '주 3~5회 운동', 'factor': 1.55},
    {'label': '활발한 활동', 'desc': '주 6~7회 운동', 'factor': 1.725},
  ];

  int _calcTDEE() {
    // Harris-Benedict BMR
    double bmr;
    if (_gender == 'male') {
      bmr = 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
    } else {
      bmr = 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
    }
    final factor = _activities[_activity]['factor'] as double;
    return (bmr * factor).round();
  }

  Future<void> _save() async {
    final tdee = _calcTDEE();
    await PrefsService.setDailyGoal(tdee);
    // 탄 50%, 단 30%, 지 20% 기준 (칼로리 → 그램)
    final carbsG = (tdee * 0.5 / 4).round();   // 탄수화물 1g = 4kcal
    final proteinG = (tdee * 0.3 / 4).round();  // 단백질 1g = 4kcal
    final fatG = (tdee * 0.2 / 9).round();      // 지방 1g = 9kcal
    await PrefsService.setNutrientGoals(carbsG, proteinG, fatG);
    await PrefsService.setOnboarded(true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress
              Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 40),

              // Steps
              Expanded(child: _buildStep()),

              // Buttons
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('이전'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canProceed() ? () {
                        if (_step < 3) {
                          setState(() => _step++);
                        } else {
                          _save();
                        }
                      } : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_step < 3 ? '다음' : '시작하기', style: const TextStyle(fontSize: 16)),
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

  bool _canProceed() {
    if (_step == 0) return _gender.isNotEmpty;
    return true;
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _genderStep();
      case 1: return _bodyStep();
      case 2: return _activityStep();
      case 3: return _resultStep();
      default: return const SizedBox();
    }
  }

  Widget _genderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('성별을 알려주세요', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('정확한 칼로리 계산을 위해 필요해요', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _genderCard('male', '👨', '남성')),
            const SizedBox(width: 16),
            Expanded(child: _genderCard('female', '👩', '여성')),
          ],
        ),
      ],
    );
  }

  Widget _genderCard(String value, String emoji, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _bodyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('신체 정보', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('기초대사량 계산에 사용돼요', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 40),

        // 나이
        _sliderTile('나이', '$_age세', _age.toDouble(), 10, 80, (v) => setState(() => _age = v.round())),
        const SizedBox(height: 24),

        // 키
        _sliderTile('키', '${_height.round()}cm', _height, 130, 210, (v) => setState(() => _height = v)),
        const SizedBox(height: 24),

        // 몸무게
        _sliderTile('몸무게', '${_weight.round()}kg', _weight, 30, 150, (v) => setState(() => _weight = v)),
      ],
    );
  }

  Widget _sliderTile(String label, String value, double current, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: current,
          min: min,
          max: max,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _activityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('활동량은 어떤가요?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('일일 소비 칼로리를 계산해요', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        for (var i = 0; i < _activities.length; i++) ...[
          _activityCard(i),
          if (i < _activities.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _activityCard(int index) {
    final selected = _activity == index;
    final a = _activities[index];
    return GestureDetector(
      onTap: () => setState(() => _activity = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.textHint, width: 2),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['label'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textPrimary)),
                Text(a['desc'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultStep() {
    final tdee = _calcTDEE();
    final carbsG = (tdee * 0.5 / 4).round();
    final proteinG = (tdee * 0.3 / 4).round();
    final fatG = (tdee * 0.2 / 9).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('맞춤 목표가\n설정되었어요!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 32),

        // 칼로리
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('일일 권장 칼로리', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('$tdee kcal', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 탄단지
        Row(
          children: [
            _nutrientResult('탄수화물', '${carbsG}g', '50%', AppColors.carbs),
            const SizedBox(width: 12),
            _nutrientResult('단백질', '${proteinG}g', '30%', AppColors.protein),
            const SizedBox(width: 12),
            _nutrientResult('지방', '${fatG}g', '20%', AppColors.fat),
          ],
        ),

        const SizedBox(height: 24),
        const Text('설정에서 언제든 변경할 수 있어요', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
      ],
    );
  }

  Widget _nutrientResult(String label, String value, String pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(pct, style: TextStyle(fontSize: 11, color: color.withAlpha(150))),
          ],
        ),
      ),
    );
  }
}
