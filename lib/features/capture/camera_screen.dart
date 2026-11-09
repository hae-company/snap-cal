import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/food_analysis_repository.dart';
import '../../shared/widgets/brand.dart';
import 'result_screen.dart';

/// 촬영 → 분석. 테마와 상관없이 어두운 몰입형 화면.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, this.presetMeal});

  /// 오늘 화면의 "아침 기록하기" 등에서 들어오면 끼니를 미리 고정한다.
  final String? presetMeal;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  String? _analyzingPath;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<XFile?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      return await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      if (source != ImageSource.camera) rethrow;
      // 카메라를 쓸 수 없는 환경(시뮬레이터 등) → 앨범으로 전환
      if (mounted) _toast('카메라를 사용할 수 없어요. 앨범에서 선택해주세요.');
      return picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
    }
  }

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final picked = await _pickImage(source);
    if (picked == null || !mounted) return;

    setState(() => _analyzingPath = picked.path);
    try {
      final bytes = await picked.readAsBytes();
      final result = await ref
          .read(foodAnalysisRepositoryProvider)
          .analyze(bytes);
      if (!mounted) return;
      if (result.hasError) {
        _toast(result.error!);
      } else {
        HapticFeedback.lightImpact();
        context.pushReplacement(
          Routes.result,
          extra: ResultArgs(
            result: result,
            imagePath: picked.path,
            presetMeal: widget.presetMeal,
          ),
        );
        return;
      }
    } on MissingApiKeyException catch (e) {
      if (mounted) _toast(e.toString());
    } catch (e) {
      if (mounted) _toast('분석에 실패했어요. 다시 시도해주세요.\n($e)');
    }
    if (mounted) setState(() => _analyzingPath = null);
  }

  @override
  Widget build(BuildContext context) {
    final analyzing = _analyzingPath != null;

    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final p = context.palette;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: AppBrand.ink,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xs,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: analyzing ? null : () => context.pop(),
                            tooltip: '닫기',
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const Spacer(),
                          Text(
                            analyzing ? 'AI 분석 중' : '음식 촬영',
                            style: AppText.headline.copyWith(color: p.text1),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xxl,
                          ),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: ViewfinderFrame(
                              strokeWidth: 5,
                              cornerLength: 44,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sheet,
                                  ),
                                  child: analyzing
                                      ? _Scanning(path: _analyzingPath!)
                                      : const _Idle(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: analyzing
                          ? const _AnalyzingMessage()
                          : Wrap(
                              spacing: AppSpace.xs,
                              children: const [
                                _TipChip(
                                  icon: Icons.arrow_downward_rounded,
                                  label: '위에서 찍기',
                                ),
                                _TipChip(
                                  icon: Icons.light_mode_rounded,
                                  label: '밝은 곳에서',
                                ),
                                _TipChip(
                                  icon: Icons.ramen_dining_rounded,
                                  label: '한 상 전체도 OK',
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Opacity(
                      opacity: analyzing ? 0.3 : 1,
                      child: IgnorePointer(
                        ignoring: analyzing,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundAction(
                              icon: Icons.photo_library_rounded,
                              label: '앨범',
                              onTap: () => _pick(ImageSource.gallery),
                            ),
                            _ShutterButton(
                              onTap: () => _pick(ImageSource.camera),
                            ),
                            const SizedBox(width: 64),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0x2612B76A), Color(0x00000000)],
          radius: 0.9,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rice_bowl_rounded, size: 72, color: p.text1.withAlpha(40)),
          const SizedBox(height: AppSpace.md),
          Text(
            '음식이 프레임 안에\n가득 차게 찍어주세요',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: p.text2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 찍은 사진 위로 초록 스캔 줄이 오르내린다.
class _Scanning extends StatefulWidget {
  const _Scanning({required this.path});
  final String path;

  @override
  State<_Scanning> createState() => _ScanningState();
}

class _ScanningState extends State<_Scanning>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(widget.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: AppBrand.inkTop),
        ),
        const ColoredBox(color: Color(0x33000000)),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Align(
            alignment: Alignment(
              0,
              Curves.easeInOut.transform(_ctrl.value) * 2 - 1,
            ),
            child: Container(
              height: 90,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x006CF5B4),
                    Color(0x556CF5B4),
                    Color(0xFF6CF5B4),
                  ],
                  stops: [0, 0.94, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalyzingMessage extends StatefulWidget {
  const _AnalyzingMessage();

  @override
  State<_AnalyzingMessage> createState() => _AnalyzingMessageState();
}

class _AnalyzingMessageState extends State<_AnalyzingMessage> {
  static const _messages = [
    '음식을 찾고 있어요',
    '양을 재고 있어요',
    '영양성분을 계산하고 있어요',
    '거의 다 됐어요',
  ];
  int _i = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (_i < _messages.length - 1) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 32,
      child: AnimatedSwitcher(
        duration: AppMotion.page,
        child: Row(
          key: ValueKey(_i),
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppBrand.neon,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(_messages[_i], style: AppText.label.copyWith(color: p.text1)),
          ],
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppBrand.neon),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.micro.copyWith(fontSize: 12, color: p.text2),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: p.surfaceAlt,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 56,
              child: Icon(icon, color: p.text1),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppText.micro.copyWith(color: p.text2)),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '카메라로 촬영',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppBrand.neonGradient,
              boxShadow: [
                BoxShadow(color: AppBrand.green.withAlpha(110), blurRadius: 24),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppBrand.ink,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
