import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/date_key.dart';
import '../../core/meal_type.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/food_record.dart';
import '../../data/providers.dart';
import '../../data/services/photo_store.dart';
import '../../shared/widgets/pickers.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/input_dialog.dart';

class ResultArgs {
  const ResultArgs({
    required this.result,
    required this.imagePath,
    this.presetMeal,
    this.date,
  });
  final AnalysisResult result;
  final String imagePath;
  final String? presetMeal;

  /// 지난 날짜에 기록할 때 (yyyy-MM-dd). 없으면 오늘.
  final String? date;
}

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.args});
  final ResultArgs args;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late String _meal =
      widget.args.presetMeal ??
      MealType.detect(DateTime.now(), ref.read(mealTimesProvider));
  late int _calories = widget.args.result.calories;
  late int _carbs = widget.args.result.carbs;
  late int _protein = widget.args.result.protein;
  late int _fat = widget.args.result.fat;

  /// 위 값들은 1인분 기준. 화면과 저장 값은 [_servings]를 곱한다.
  double _servings = 1;
  int _s(int v) => (v * _servings).round();
  int Function(int) get _base =>
      (v) => (v / _servings).round();
  bool _saving = false;

  AnalysisResult get _result => widget.args.result;

  Future<void> _edit(
    String label,
    int current,
    String unit,
    ValueChanged<int> onSave,
  ) async {
    final value = await showNumberDialog(
      context,
      title: '$label 수정',
      initial: current,
      suffix: unit,
    );
    if (value != null) setState(() => onSave(value.toInt()));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(mealActionsProvider)
        .add(
          FoodRecord(
            date: widget.args.date ?? dateKey(DateTime.now()),
            mealType: _meal,
            foodName: _result.foodName,
            calories: _s(_calories),
            carbs: _s(_carbs),
            protein: _s(_protein),
            fat: _s(_fat),
            servings: _servings,
            source: RecordSource.ai,
            imagePath: await PhotoStore.keep(widget.args.imagePath),
            description: _result.description,
          ),
        );
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${MealType.label(_meal)}에 ${formatKcal(_s(_calories))} kcal를 기록했어요',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: p.bg,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                onPressed: () => context.pop(),
                tooltip: '닫기',
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.args.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: p.surfaceAlt,
                      child: Icon(
                        Icons.rice_bowl_rounded,
                        size: 64,
                        color: p.text3,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x66000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpace.screen,
                    bottom: AppSpace.lg,
                    child: _confidence(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.xl,
                AppSpace.screen,
                AppSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_result.foodName, style: AppText.title1),
                  if (_result.servingInfo.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    _Pill(
                      icon: Icons.restaurant_rounded,
                      text: _result.servingInfo,
                      color: p.brand,
                      background: p.brandSubtle,
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  Semantics(
                    button: true,
                    label: '칼로리 ${_s(_calories)}, 탭하여 수정',
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      onTap: () => _edit(
                        '칼로리',
                        _s(_calories),
                        'kcal',
                        (v) => _calories = _base(v),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatKcal(_s(_calories)),
                            style: AppText.display.copyWith(
                              fontSize: 48,
                              color: p.text1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'kcal',
                              style: AppText.headline.copyWith(color: p.text2),
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: p.text3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    _result.totalCalories > 0 &&
                            _result.totalCalories != _result.calories
                        ? '${formatServings(_servings)}인분 기준 · 사진 전체는 약 ${formatKcal(_result.totalCalories)} kcal'
                        : '${formatServings(_servings)}인분 기준',
                    style: AppText.caption.copyWith(color: p.text2),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ServingStepper(
                    value: _servings,
                    onChanged: (v) => setState(() => _servings = v),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: [
                      _MacroTile(
                        label: '탄수화물',
                        grams: _s(_carbs),
                        color: p.carbs,
                        onTap: () => _edit(
                          '탄수화물',
                          _s(_carbs),
                          'g',
                          (v) => _carbs = _base(v),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _MacroTile(
                        label: '단백질',
                        grams: _s(_protein),
                        color: p.protein,
                        onTap: () => _edit(
                          '단백질',
                          _s(_protein),
                          'g',
                          (v) => _protein = _base(v),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _MacroTile(
                        label: '지방',
                        grams: _s(_fat),
                        color: p.fat,
                        onTap: () =>
                            _edit('지방', _s(_fat), 'g', (v) => _fat = _base(v)),
                      ),
                    ],
                  ),
                  if (_result.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: p.brand,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              _result.description,
                              style: AppText.caption.copyWith(color: p.text2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  const Text('어느 끼니인가요?', style: AppText.headline),
                  const SizedBox(height: AppSpace.sm),
                  MealPicker(
                    value: _meal,
                    onChanged: (t) => setState(() => _meal = t),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    '칼로리와 영양성분은 AI 추정치예요. 숫자를 눌러 고칠 수 있어요.',
                    style: AppText.micro.copyWith(
                      fontWeight: FontWeight.w400,
                      color: p.text3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.xs,
          AppSpace.screen,
          AppSpace.md,
        ),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('${MealType.label(_meal)}에 기록하기'),
        ),
      ),
    );
  }

  Widget _confidence() {
    final (label, color) = switch (_result.confidence) {
      'high' => ('정확도 높음', const Color(0xFF8BE3B0)),
      'medium' => ('정확도 보통', AppBrand.spark),
      _ => ('확인이 필요해요', const Color(0xFFFCA5A5)),
    };
    return _Pill(
      icon: Icons.auto_awesome_rounded,
      text: label,
      color: color,
      background: Colors.black54,
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.grams,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int grams;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label $grams그램, 탭하여 수정',
        excludeSemantics: true,
        child: Material(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppText.micro.copyWith(
                          fontSize: 12,
                          color: p.text2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$grams',
                          style: AppText.numeric(AppText.title2),
                        ),
                        TextSpan(
                          text: ' g',
                          style: AppText.caption.copyWith(color: p.text2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppText.micro.copyWith(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
