import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/analysis_result.dart';
import '../utils/prompt.dart';

class GeminiService {
  static Future<AnalysisResult> analyzeFood(String apiKey, File imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );

    final imageBytes = await imageFile.readAsBytes();
    final content = Content.multi([
      TextPart(geminiPrompt),
      DataPart('image/jpeg', imageBytes),
    ]);

    final response = await model.generateContent([content]);
    final text = response.text ?? '';

    // Extract JSON from response
    final jsonStr = _extractJson(text);
    if (jsonStr == null) {
      return AnalysisResult(
        foodName: '', calories: 0, carbs: 0, protein: 0, fat: 0,
        confidence: '', description: '', error: 'AI 응답을 파싱할 수 없습니다',
      );
    }

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AnalysisResult.fromJson(json);
  }

  static String? _extractJson(String text) {
    // Try to find JSON in the response
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}
