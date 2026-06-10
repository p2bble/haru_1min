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
  // responseSchema(JSON 모드)로 출력 형식을 강제해 파싱 실패를 차단
  static final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: Schema.object(properties: {
        'name': Schema.string(
            description: '제품에서 읽히는 영양제 이름 (예: 오메가3). 읽을 수 없으면 빈 문자열'),
        'meal_time': Schema.enumString(enumValues: ['아침', '점심', '저녁', '자기전']),
        'tip': Schema.string(description: '복용 팁 한 문장'),
      }),
    ),
  );

  static const _prompt = '''
이 영양제 사진을 분석해서 이름, 가장 적합한 복용 시간, 복용 팁 한 문장을 알려줘.

복용 시간 판단 기준:
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

      final data = jsonDecode(response.text ?? '') as Map<String, dynamic>;

      final name = (data['name'] as String?)?.trim();
      return SupplementAiResult(
        name: (name == null || name.isEmpty) ? null : name,
        mealTime: _mealTimeMap[data['meal_time'] as String?] ?? 'morning',
        tip: data['tip'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
