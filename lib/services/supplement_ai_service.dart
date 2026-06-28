import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/supplement.dart';

class SupplementAiResult {
  final String? name;
  final String mealTime; // morning / lunch / dinner / bedtime
  final String? tip;
  final List<NutrientAmount> nutrients;

  const SupplementAiResult({
    this.name,
    required this.mealTime,
    this.tip,
    this.nutrients = const [],
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
            description:
                '"{브랜드} {제품명}" 형식의 영양제 이름. 마케팅 수식어 제외. 읽을 수 없으면 빈 문자열'),
        'meal_time': Schema.enumString(enumValues: ['아침', '점심', '저녁', '자기전']),
        'tip': Schema.string(description: '제품 성분에 맞춘 복용 팁 한 문장'),
        'nutrients': Schema.array(
          description: '라벨에서 읽은 주요 영양소. 표가 안 보이면 빈 배열',
          items: Schema.object(
            properties: {
              'key': Schema.enumString(
                enumValues: _nutrientKeys,
                description: '영양소 표준 키',
              ),
              'amount': Schema.number(description: '1정(회)당 함량. 표기 없으면 생략'),
              'unit': Schema.enumString(enumValues: ['mg', 'ug', 'IU']),
            },
            // 원재료명만 있고 함량표가 없으면 key만 채울 수 있어야 한다.
            // (기본은 모든 속성 required → amount/unit 없는 성분이 통째로 누락됨)
            optionalProperties: ['amount', 'unit'],
          ),
        ),
      }),
    ),
  );

  // nutrient_info.dart의 kNutrients 키와 1:1로 유지해야 한다.
  static const _nutrientKeys = [
    'vitamin_a', 'vitamin_d', 'vitamin_e', 'vitamin_c', 'vitamin_b6',
    'folate', 'niacin', 'calcium', 'iron', 'zinc', 'copper',
    'selenium', 'manganese', 'iodine', 'magnesium', //
  ];

  static const _prompt = '''
이 영양제 사진을 분석해서 이름, 가장 적합한 복용 시간, 복용 팁 한 문장을 JSON으로 채워줘.

[이름 규칙]
- 형식: "{브랜드} {제품명}" — 브랜드가 보이면 앞에 붙여 목록에서 구분되게 한다.
- '올인원/프리미엄/고함량' 같은 수식어·마케팅 문구는 빼고 핵심 제품명만 남긴다.
- 영문·한글이 함께 있으면 통용되는 한쪽으로 간결하게 (예: "H&B ABC-Z 종합비타민").

[복용 시간 기준]
- 지용성(오메가3, 비타민 A·D·E·K, 코엔자임Q10) → 식사와 함께 (아침/저녁)
- 수용성 비타민(B군, C) → 아침
- 마그네슘·테아닌 등 수면 도움 → 자기전
- 유산균 → 아침 공복

[복용 팁 규칙]
- 라벨의 '원재료명 및 함량'을 읽고, 이 제품에 실제로 든 성분에 맞춘 한 문장으로 쓴다.
- 가능하면 성분 간 상호작용·흡수 정보를 우선한다.
  예) 철분+비타민C는 흡수↑ / 칼슘·철·아연을 동시에 다량이면 흡수 경쟁 /
      마그네슘은 취침 전 분리 복용 / 지용성 비타민은 식후 흡수↑
- 해당하는 성분 정보가 없으면 일반적인 섭취 팁으로 대체한다.
- 효능·치료·예방을 단정하는 의학적 표현은 금지(건강기능식품 규정).
  "흡수를 돕습니다" 수준의 섭취 가이드 톤을 유지한다.
- 제품마다 다른 문장이 되도록, 똑같은 상투구를 반복하지 않는다.

[성분(nutrients) 추출]
- '원재료명 및 함량' 또는 '영양·기능정보' 표에서, 표준 키 목록에 해당하는 성분을 담는다.
- 원재료명은 화학물질명으로 적혀 있어도 해당 영양소로 매핑한다.
  예) 레티닐아세트산염→vitamin_a, 산화아연→zinc, 셀렌산나트륨→selenium,
      푸마르산제일철→iron, 글루콘산동→copper, 니코틴산아미드→niacin, 탄산칼슘→calcium
- 1정(1회)당 함량과 단위(mg/ug/IU)가 보이면 함께, 없으면 key만 담는다(종류만으로 충분).
- 라벨에 근거가 보이는 성분만 담고, 안 보이면 빈 배열로 둔다. 추측해서 만들지 않는다.
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
        nutrients: _parseNutrients(data['nutrients']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<NutrientAmount> _parseNutrients(dynamic raw) {
    if (raw is! List) return const [];
    final result = <NutrientAmount>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final key = e['key'] as String?;
      if (key == null || key.isEmpty) continue;
      result.add(NutrientAmount(
        key: key,
        amount: (e['amount'] as num?)?.toDouble(),
        unit: e['unit'] as String?,
      ));
    }
    return result;
  }
}
