import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/food_analysis_repository.dart';
import 'result_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _analyzing = false;

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
      // 카메라를 쓸 수 없는 환경(시뮬레이터 등) → 갤러리로 전환
      if (mounted) _toast('카메라를 사용할 수 없어요. 갤러리에서 선택해주세요.');
      return picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
    }
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _pickImage(source);
    if (picked == null || !mounted) return;

    setState(() => _analyzing = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await ref
          .read(foodAnalysisRepositoryProvider)
          .analyze(bytes);
      if (!mounted) return;
      if (result.hasError) {
        _toast(result.error!);
      } else {
        context.push(
          Routes.result,
          extra: ResultArgs(result: result, imagePath: picked.path),
        );
      }
    } on MissingApiKeyException catch (e) {
      if (mounted) _toast(e.toString());
    } catch (e) {
      if (mounted) _toast('분석 실패: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
          child: _analyzing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'AI가 음식을 분석하고 있어요...',
                      style: AppText.body.copyWith(color: p.text2),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant, size: 64, color: p.brand),
                    const SizedBox(height: AppSpace.md),
                    const Text('음식 사진을 찍어주세요', style: AppText.title2),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'AI가 칼로리를 분석해드려요',
                      style: AppText.body.copyWith(color: p.text2),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    FilledButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('카메라로 촬영'),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: Icon(Icons.photo_library, color: p.brand),
                      label: const Text('갤러리에서 선택'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
