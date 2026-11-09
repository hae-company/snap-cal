import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../../core/nutrition_calc.dart';
import '../../data/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/export_service.dart';
import '../../data/repositories/food_analysis_repository.dart';
import '../../shared/meal_style.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/input_dialog.dart';
import '../../shared/widgets/number_field.dart';
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
    final reminders = ref.watch(remindersProvider);

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

          const _GroupTitle('끼니 알림'),
          _Group([for (final r in reminders) _ReminderTile(reminder: r)]),
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

          const _GroupTitle('데이터'),
          _Group([
            _Tile(
              leading: _IconBox(Icons.ios_share_rounded, p.brand),
              title: '식단 기록 내보내기 (CSV)',
              onTap: () => _export(context, ref),
            ),
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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final records = await ref.read(mealRepositoryProvider).all();
    if (!context.mounted) return;
    if (records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내보낼 기록이 아직 없어요')));
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    await shareMealsCsv(
      records,
      origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _editApiKey(BuildContext context, WidgetRef ref) async {
    final saved = await showInputDialog(
      context,
      title: 'Gemini API 키',
      message: 'Google AI Studio에서 무료로 발급받을 수 있어요',
      hint: 'API 키 입력',
      initial: ref.read(apiKeyProvider),
      obscure: true,
    );
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
                const SizedBox(height: AppSpace.md),
                Text(
                  [
                    '물 ${formatKcal(ref.watch(waterGoalProvider))}ml',
                    if (ref.watch(targetWeightProvider) case final t?)
                      '목표 체중 ${t.toStringAsFixed(1)}kg',
                  ].join('  ·  '),
                  style: AppText.caption.copyWith(color: dim),
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
  late final _water = TextEditingController(
    text: '${ref.read(waterGoalProvider)}',
  );
  late final _target = TextEditingController(
    text: ref.read(targetWeightProvider)?.toStringAsFixed(1) ?? '',
  );

  @override
  void dispose() {
    for (final c in [_kcal, _carbs, _protein, _fat, _water, _target]) {
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
    await ref
        .read(waterGoalProvider.notifier)
        .set((int.tryParse(_water.text) ?? 2000).clamp(250, 6000));
    final target = double.tryParse(_target.text);
    await ref
        .read(targetWeightProvider.notifier)
        .set(target != null && target >= 20 && target <= 300 ? target : null);
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
            NumberField(
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
                  child: NumberField(
                    label: '탄수화물',
                    controller: _carbs,
                    unit: 'g',
                    color: p.carbs,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: NumberField(
                    label: '단백질',
                    controller: _protein,
                    unit: 'g',
                    color: p.protein,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: NumberField(
                    label: '지방',
                    controller: _fat,
                    unit: 'g',
                    color: p.fat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    label: '물',
                    controller: _water,
                    unit: 'ml',
                    color: p.carbs,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: NumberField(
                    label: '목표 체중',
                    controller: _target,
                    unit: 'kg',
                    color: p.text3,
                    decimal: true,
                    hint: '선택',
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

/// 끼니 알림 한 줄: 시간 (눌러서 변경) + 켜기/끄기
class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});
  final MealReminder reminder;

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    MealReminder next,
  ) async {
    final ok = await ref.read(remindersProvider.notifier).change(next);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 권한이 꺼져 있어요. 설정 앱에서 스냅칼 알림을 허용해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = reminder;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          MealBadge(type: r.mealType, size: 28),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(MealType.label(r.mealType), style: AppText.body),
          ),
          TextButton(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
                helpText: '${MealType.label(r.mealType)} 알림 시간',
              );
              if (t != null && context.mounted) {
                await _change(
                  context,
                  ref,
                  r.copyWith(hour: t.hour, minute: t.minute, enabled: true),
                );
              }
            },
            child: Text(
              r.timeLabel,
              style: AppText.numeric(
                AppText.label,
              ).copyWith(color: r.enabled ? p.text1 : p.text3),
            ),
          ),
          Switch(
            value: r.enabled,
            onChanged: (on) => _change(context, ref, r.copyWith(enabled: on)),
          ),
        ],
      ),
    );
  }
}
