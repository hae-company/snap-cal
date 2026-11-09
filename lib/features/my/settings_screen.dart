import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/meal_type.dart';
import '../../core/nutrition_calc.dart';
import '../../data/providers.dart';
import '../../data/repositories/food_analysis_repository.dart';
import '../../shared/widgets/sheet_handle.dart';
import 'policy_texts.dart';

const _appVersion = '1.0.0';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final NutritionGoals _initial = ref.read(goalsProvider);
  late final _kcalCtrl = TextEditingController(text: '${_initial.kcal}');
  late final _carbsCtrl = TextEditingController(text: '${_initial.carbsG}');
  late final _proteinCtrl = TextEditingController(text: '${_initial.proteinG}');
  late final _fatCtrl = TextEditingController(text: '${_initial.fatG}');

  @override
  void dispose() {
    for (final c in [_kcalCtrl, _carbsCtrl, _proteinCtrl, _fatCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _saveGoals() async {
    final d = NutritionGoals.defaults;
    await ref
        .read(goalsProvider.notifier)
        .save(
          NutritionGoals(
            kcal: int.tryParse(_kcalCtrl.text) ?? d.kcal,
            carbsG: int.tryParse(_carbsCtrl.text) ?? d.carbsG,
            proteinG: int.tryParse(_proteinCtrl.text) ?? d.proteinG,
            fatG: int.tryParse(_fatCtrl.text) ?? d.fatG,
          ),
        );
    if (mounted) _toast('설정이 저장되었어요');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final apiKey = ref.watch(apiKeyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final mealTimes = ref.watch(mealTimesProvider);

    String range(String type) {
      final r = mealTimes[type]!;
      String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
      return '${hh(r[0])} ~ ${hh(r[1])}';
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.md,
              AppSpace.screen,
              AppSpace.lg,
            ),
            child: Text('설정', style: AppText.title1),
          ),

          const _SectionHeader('🎯 목표 설정'),
          _SettingCard([
            _NumberTile(
              leading: Icon(Icons.local_fire_department, color: p.brand),
              label: '일일 칼로리 목표',
              controller: _kcalCtrl,
              suffix: 'kcal',
              width: 100,
            ),
          ]),
          const SizedBox(height: AppSpace.xs),
          _SettingCard([
            _NumberTile(
              leading: CircleAvatar(radius: 6, backgroundColor: p.carbs),
              label: '탄수화물',
              controller: _carbsCtrl,
              suffix: 'g',
            ),
            const Divider(),
            _NumberTile(
              leading: CircleAvatar(radius: 6, backgroundColor: p.protein),
              label: '단백질',
              controller: _proteinCtrl,
              suffix: 'g',
            ),
            const Divider(),
            _NumberTile(
              leading: CircleAvatar(radius: 6, backgroundColor: p.fat),
              label: '지방',
              controller: _fatCtrl,
              suffix: 'g',
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              0,
            ),
            child: FilledButton(
              onPressed: _saveGoals,
              child: const Text('목표 저장'),
            ),
          ),
          const SizedBox(height: AppSpace.xl),

          const _SectionHeader('⏰ 식사 시간대'),
          _SettingCard([
            for (final type in [
              MealType.breakfast,
              MealType.lunch,
              MealType.dinner,
            ]) ...[
              _InfoTile(
                '${MealType.emoji(type)} ${MealType.label(type)}',
                range(type),
              ),
              const Divider(),
            ],
            _InfoTile(
              '${MealType.emoji(MealType.snack)} ${MealType.label(MealType.snack)}',
              '그 외 시간',
            ),
          ]),
          const SizedBox(height: AppSpace.xl),

          const _SectionHeader('🎨 화면'),
          _SettingCard([
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('테마'),
              trailing: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('시스템')),
                  ButtonSegment(value: ThemeMode.light, label: Text('라이트')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('다크')),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ]),
          const SizedBox(height: AppSpace.xl),

          const _SectionHeader('🤖 AI 설정'),
          _SettingCard([
            ListTile(
              leading: Icon(Icons.key, color: p.brand),
              title: const Text('Gemini API Key'),
              subtitle: Text(
                apiKey.isEmpty
                    ? '설정되지 않음'
                    : '••••••${apiKey.substring(apiKey.length > 6 ? apiKey.length - 4 : 0)}',
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: apiKey.isEmpty ? p.over : p.text2,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: p.text3),
              onTap: _showApiKeyDialog,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.smart_toy, color: p.brand),
              title: const Text('AI 모델'),
              subtitle: const Text(GeminiDirectAnalysisRepository.model),
            ),
          ]),
          const SizedBox(height: AppSpace.xl),

          const _SectionHeader('📦 데이터 관리'),
          _SettingCard([
            ListTile(
              leading: Icon(Icons.delete_outline, color: p.over),
              title: const Text('기록 전체 삭제'),
              subtitle: const Text('모든 식단 기록이 삭제돼요'),
              trailing: Icon(Icons.chevron_right, color: p.text3),
              onTap: _confirmReset,
            ),
          ]),
          const SizedBox(height: AppSpace.xl),

          const _SectionHeader('ℹ️ 정보'),
          _SettingCard([
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('버전'),
              trailing: Text(_appVersion),
            ),
            const Divider(),
            _LinkTile(
              Icons.privacy_tip_outlined,
              '개인정보처리방침',
              () => _showPolicy('개인정보처리방침', privacyPolicyText),
            ),
            const Divider(),
            _LinkTile(
              Icons.description_outlined,
              '이용약관',
              () => _showPolicy('이용약관', termsOfServiceText),
            ),
            const Divider(),
            _LinkTile(
              Icons.code,
              '오픈소스 라이선스',
              () => showLicensePage(
                context: context,
                applicationName: 'SnapCal',
                applicationVersion: _appVersion,
              ),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('문의하기'),
              subtitle: Text('hae02y@gmail.com'),
            ),
          ]),
          const SizedBox(height: AppSpace.xl),

          Center(
            child: Column(
              children: [
                Text(
                  'SnapCal',
                  style: AppText.headline.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by hae02y',
                  style: AppText.micro.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: p.text3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final ctrl = TextEditingController(text: ref.read(apiKeyProvider));
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => _ApiKeyDialog(controller: ctrl),
    );
    ctrl.dispose();
    if (saved != null)
      await ref.read(apiKeyProvider.notifier).set(saved.trim());
  }

  Future<void> _confirmReset() async {
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
    if (mounted) _toast('모든 기록이 삭제되었어요');
  }

  void _showPolicy(String title, String content) {
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
                    Text(
                      title,
                      style: AppText.headline.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
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
      title: const Text('Gemini API Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google AI Studio에서 무료로 발급받을 수 있어요',
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: p.text2,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: widget.controller,
            obscureText: !_visible,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'API 키 입력',
              suffixIcon: IconButton(
                icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.xs,
      ),
      child: Text(
        title,
        style: AppText.label.copyWith(color: context.palette.text2),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.leading,
    required this.label,
    required this.controller,
    required this.suffix,
    this.width = 80,
  });

  final Widget leading;
  final String label;
  final TextEditingController controller;
  final String suffix;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(label),
      trailing: SizedBox(
        width: width,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.right,
          style: AppText.numeric(AppText.headline.copyWith(fontSize: 16)),
          decoration: InputDecoration(
            suffixText: suffix,
            isDense: true,
            filled: false,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: AppText.label.copyWith(fontWeight: FontWeight.w400),
      ),
      trailing: Text(
        value,
        style: AppText.numeric(
          AppText.label,
        ).copyWith(fontWeight: FontWeight.w400, color: context.palette.text2),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: context.palette.text3),
      onTap: onTap,
    );
  }
}
