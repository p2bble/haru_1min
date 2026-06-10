import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';

class SupplementAiResult {
  final String? name;
  final String mealTime; // morning / lunch / dinner / bedtime
  final String? tip;

  const SupplementAiResult({
    this.name,
    required this.mealTime,
    this.tip,
  });
}

/// 영양제 병/포장 사진을 Gemini로 분석해 이름·권장 복용 시간·복용 팁을 추출
class SupplementAiService {
  static final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );

  static const _prompt = '''
이 영양제 사진을 분석해서 아래 JSON 형식으로만 응답해. 설명 없이 JSON만 반환해.

{
  "name": "제품에서 읽히는 영양제 이름 (예: 오메가3, 비타민D 1000IU). 읽을 수 없으면 null",
  "meal_time": "아침" | "점심" | "저녁" | "자기전" 중 이 영양제에 가장 적합한 복용 시간 하나,
  "tip": "복용 팁 한 문장 (예: 지용성이라 식사 직후 복용하면 흡수가 좋아요)"
}

판단 기준:
- 지용성(오메가3, 비타민D/A/E, 코엔자임Q10 등) → 식사와 함께 (아침/저녁)
- 수용성 비타민(B, C) → 아침
- 마그네슘, 테아닌 등 수면 도움 → 자기전
- 유산균 → 아침 공복
''';

  static const _mealTimeMap = {
    '아침': 'morning',
    '점심': 'lunch',
    '저녁': 'dinner',
    '자기전': 'bedtime',
  };

  static Future<SupplementAiResult?> analyze(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final imagePart = InlineDataPart('image/jpeg', bytes);
      final response = await _model.generateContent([
        Content.multi([imagePart, TextPart(_prompt)]),
      ]);

      final raw = response.text ?? '';
      final jsonStr =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      return SupplementAiResult(
        name: data['name'] as String?,
        mealTime: _mealTimeMap[data['meal_time'] as String?] ?? 'morning',
        tip: data['tip'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
