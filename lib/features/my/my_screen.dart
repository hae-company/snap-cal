import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../../core/nutrition_calc.dart';
import '../../data/providers.dart';
import '../../data/repositories/food_analysis_repository.dart';
import '../../shared/meal_style.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/sheet_handle.dart';
import 'policy_texts.dart';

const appVersion = '1.0.0';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final apiKey = ref.watch(apiKeyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final mealTimes = ref.watch(mealTimesProvider);

    String range(String type) {
      final r = mealTimes[type]!;
      String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
      return '${hh(r[0])} – ${hh(r[1])}';
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.sm,
          AppSpace.screen,
          120,
        ),
        children: [
          const Text('MY', style: AppText.title1),
          const SizedBox(height: AppSpace.md),
          const _GoalCard(),
          const SizedBox(height: AppSpace.xl),

          const _GroupTitle('끼니 시간'),
          _Group([
            for (final t in [
              MealType.breakfast,
              MealType.lunch,
              MealType.dinner,
            ])
              _Tile(
                leading: MealBadge(type: t, size: 28),
                title: MealType.label(t),
                value: range(t),
              ),
            _Tile(
              leading: const MealBadge(type: MealType.snack, size: 28),
              title: '간식',
              value: '그 외 시간',
            ),
          ]),
          const SizedBox(height: AppSpace.lg),

          const _GroupTitle('화면'),
          _Group([
            Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('시스템'),
                      icon: Icon(Icons.brightness_auto_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('라이트'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('다크'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpace.lg),

          const _GroupTitle('AI 분석'),
          _Group([
            _Tile(
              leading: _IconBox(Icons.key_rounded, p.brand),
              title: 'Gemini API 키',
              value: apiKey.isEmpty
                  ? '입력 필요'
                  : '••••${apiKey.substring(apiKey.length > 4 ? apiKey.length - 4 : 0)}',
              valueColor: apiKey.isEmpty ? p.over : null,
              onTap: () => _editApiKey(context, ref),
            ),
            _Tile(
              leading: _IconBox(Icons.auto_awesome_rounded, p.brand),
              title: 'AI 모델',
              value: GeminiDirectAnalysisRepository.model,
            ),
          ]),
          const SizedBox(height: AppSpace.lg),

          const _GroupTitle('정보'),
          _Group([
            _Tile(
              leading: _IconBox(Icons.privacy_tip_outlined, p.text2),
              title: '개인정보처리방침',
              onTap: () => _showPolicy(context, '개인정보처리방침', privacyPolicyText),
            ),
            _Tile(
              leading: _IconBox(Icons.description_outlined, p.text2),
              title: '이용약관',
              onTap: () => _showPolicy(context, '이용약관', termsOfServiceText),
            ),
            _Tile(
              leading: _IconBox(Icons.code_rounded, p.text2),
              title: '오픈소스 라이선스',
              onTap: () => showLicensePage(
                context: context,
                applicationName: '스냅칼',
                applicationVersion: appVersion,
              ),
            ),
            _Tile(
              leading: _IconBox(Icons.mail_outline_rounded, p.text2),
              title: '문의하기',
              value: 'hae02y@gmail.com',
            ),
          ]),
          const SizedBox(height: AppSpace.lg),

          _Group([
            _Tile(
              leading: _IconBox(Icons.delete_outline_rounded, p.over),
              title: '기록 전체 삭제',
              titleColor: p.over,
              onTap: () => _confirmReset(context, ref),
            ),
          ]),
          const SizedBox(height: AppSpace.xxl),
          Center(
            child: Opacity(
              opacity: 0.7,
              child: Wordmark(size: 28, subtitle: '버전 $appVersion'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editApiKey(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: ref.read(apiKeyProvider));
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => _ApiKeyDialog(controller: ctrl),
    );
    ctrl.dispose();
    if (saved != null) {
      await ref.read(apiKeyProvider.notifier).set(saved.trim());
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 전체 삭제'),
        content: const Text('모든 식단 기록이 삭제되며 복구할 수 없어요.\n정말 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.over),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(mealActionsProvider).deleteAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 기록이 삭제되었어요')));
    }
  }

  void _showPolicy(BuildContext context, String title, String content) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // 하단 탭 위로 띄운다
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpace.xs),
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.xs,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Text(title, style: AppText.title2.copyWith(fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.all(AppSpace.screen),
                  child: Text(
                    content,
                    style: AppText.label.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                      color: p.text2,
                    ),
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

/// 하루 목표 카드. 로고와 같은 어두운 브랜드 배경.
class _GoalCard extends ConsumerWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(goalsProvider);
    const dim = Color(0xFF9CA3AF);

    Widget macro(String label, int grams, Color c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.micro.copyWith(fontSize: 12, color: dim),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${grams}g',
            style: AppText.numeric(
              AppText.headline,
            ).copyWith(color: Colors.white),
          ),
        ],
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppBrand.inkGradient,
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x4012B76A), Color(0x0012B76A)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('하루 목표', style: AppText.label.copyWith(color: dim)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => showGoalEditor(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppBrand.neon,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0x1A6CF5B4),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('수정'),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          AppBrand.neonGradient.createShader(r),
                      child: Text(
                        formatKcal(g.kcal),
                        style: AppText.display.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'kcal',
                        style: AppText.headline.copyWith(color: dim),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    macro('탄수화물', g.carbsG, AppPalette.dark.carbs),
                    macro('단백질', g.proteinG, AppPalette.dark.protein),
                    macro('지방', g.fatG, AppPalette.dark.fat),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 목표 수정 시트
Future<void> showGoalEditor(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _GoalEditor(),
  );
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor();

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  late final NutritionGoals _g = ref.read(goalsProvider);
  late final _kcal = TextEditingController(text: '${_g.kcal}');
  late final _carbs = TextEditingController(text: '${_g.carbsG}');
  late final _protein = TextEditingController(text: '${_g.proteinG}');
  late final _fat = TextEditingController(text: '${_g.fatG}');

  @override
  void dispose() {
    for (final c in [_kcal, _carbs, _protein, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoSplit() {
    final g = NutritionGoals.fromKcal(int.tryParse(_kcal.text) ?? _g.kcal);
    setState(() {
      _carbs.text = '${g.carbsG}';
      _protein.text = '${g.proteinG}';
      _fat.text = '${g.fatG}';
    });
  }

  Future<void> _save() async {
    await ref
        .read(goalsProvider.notifier)
        .save(
          NutritionGoals(
            kcal: int.tryParse(_kcal.text) ?? _g.kcal,
            carbsG: int.tryParse(_carbs.text) ?? _g.carbsG,
            proteinG: int.tryParse(_protein.text) ?? _g.proteinG,
            fatG: int.tryParse(_fat.text) ?? _g.fatG,
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('목표를 저장했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.xs,
        AppSpace.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpace.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const Text('하루 목표 수정', style: AppText.title2),
            const SizedBox(height: AppSpace.lg),
            _NumberField(
              label: '칼로리',
              controller: _kcal,
              unit: 'kcal',
              color: p.brand,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _autoSplit,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('칼로리에 맞춰 탄단지 자동 계산'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: '탄수화물',
                    controller: _carbs,
                    unit: 'g',
                    color: p.carbs,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: _NumberField(
                    label: '단백질',
                    controller: _protein,
                    unit: 'g',
                    color: p.protein,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: _NumberField(
                    label: '지방',
                    controller: _fat,
                    unit: 'g',
                    color: p.fat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            FilledButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.unit,
    required this.color,
  });
  final String label;
  final TextEditingController controller;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppText.caption.copyWith(color: p.text2)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppText.numeric(AppText.headline),
          decoration: InputDecoration(suffixText: unit, isDense: true),
        ),
      ],
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.controller});
  final TextEditingController controller;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text('Gemini API 키'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google AI Studio에서 무료로 발급받을 수 있어요',
            style: AppText.caption.copyWith(color: p.text2),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: widget.controller,
            obscureText: !_visible,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'API 키 입력',
              suffixIcon: IconButton(
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                tooltip: _visible ? '숨기기' : '보기',
                onPressed: () => setState(() => _visible = !_visible),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, widget.controller.text),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpace.xxs, bottom: AppSpace.xs),
    child: Text(
      text,
      style: AppText.label.copyWith(color: context.palette.text2),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.leading,
    required this.title,
    this.value,
    this.valueColor,
    this.titleColor,
    this.onTap,
  });
  final Widget leading;
  final String title;
  final String? value;
  final Color? valueColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                title,
                style: AppText.body.copyWith(color: titleColor ?? p.text1),
              ),
            ),
            if (value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppText.numeric(
                    AppText.caption,
                  ).copyWith(color: valueColor ?? p.text2),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpace.xxs),
              Icon(Icons.chevron_right_rounded, size: 20, color: p.text3),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, size: 16, color: color),
  );
}
