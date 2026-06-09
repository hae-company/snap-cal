import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/prefs_service.dart';
import '../utils/constants.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _analyzing = false;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;

    final apiKey = await PrefsService.getApiKey();
    if (apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정에서 Gemini API 키를 먼저 입력해주세요')),
      );
      return;
    }

    setState(() => _analyzing = true);

    try {
      final result = await GeminiService.analyzeFood(apiKey, File(picked.path));
      if (!mounted) return;

      if (result.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultScreen(result: result, imagePath: picked.path),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 실패: $e')),
      );
    }

    setState(() => _analyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: _analyzing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('AI가 음식을 분석하고 있어요...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('음식 사진을 찍어주세요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('AI가 칼로리를 분석해드려요', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라로 촬영'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 선택'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
