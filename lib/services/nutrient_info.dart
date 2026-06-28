import '../models/supplement.dart';

/// 영양소 기준 정보. [ul]은 한국인 영양소 섭취기준(KDRIs 2020) 성인 기준
/// 상한섭취량(UL)을 [baseUnit]로 표기한 값. 정밀 임상치가 아니라 "과량 주의"
/// 안내용 보수적 기준이며, 공식 KDRIs 개정 시 함께 검토해야 한다.
class NutrientRef {
  final String label; // 화면 표시명
  final double? ul; // 상한섭취량 (baseUnit 단위). null = 상한 미설정
  final String baseUnit; // 'mg' 또는 'ug'
  final bool highRisk; // 과량 부작용이 잘 알려진 성분(강조 대상)

  const NutrientRef({
    required this.label,
    this.ul,
    required this.baseUnit,
    this.highRisk = false,
  });
}

/// AI 추출 키 → 기준 정보. AI 스키마의 enum 키와 1:1로 맞춰야 한다.
const kNutrients = <String, NutrientRef>{
  'vitamin_a':
      NutrientRef(label: '비타민 A', ul: 3000, baseUnit: 'ug', highRisk: true),
  'vitamin_d': NutrientRef(label: '비타민 D', ul: 100, baseUnit: 'ug'),
  'vitamin_e': NutrientRef(label: '비타민 E', ul: 540, baseUnit: 'mg'),
  'vitamin_c': NutrientRef(label: '비타민 C', ul: 2000, baseUnit: 'mg'),
  'vitamin_b6': NutrientRef(label: '비타민 B6', ul: 100, baseUnit: 'mg'),
  'folate': NutrientRef(label: '엽산', ul: 1000, baseUnit: 'ug'),
  'niacin': NutrientRef(label: '니아신', ul: 35, baseUnit: 'mg'), // 니코틴산 기준(보수적)
  'calcium': NutrientRef(label: '칼슘', ul: 2500, baseUnit: 'mg'),
  'iron': NutrientRef(label: '철', ul: 45, baseUnit: 'mg', highRisk: true),
  'zinc': NutrientRef(label: '아연', ul: 35, baseUnit: 'mg', highRisk: true),
  'copper': NutrientRef(label: '구리', ul: 10000, baseUnit: 'ug'),
  'selenium':
      NutrientRef(label: '셀레늄', ul: 400, baseUnit: 'ug', highRisk: true),
  'manganese': NutrientRef(label: '망간', ul: 11, baseUnit: 'mg'),
  'iodine': NutrientRef(label: '요오드', ul: 2400, baseUnit: 'ug'),
  'magnesium': NutrientRef(label: '마그네슘', ul: 350, baseUnit: 'mg'), // 보충제 기준
};

enum NutrientLevel {
  ok, // 단일 제품, 상한 여유 — 노출 안 함
  overlap, // 2개 이상 제품에 중복(함량 미상 또는 상한 여유)
  nearLimit, // 합산이 상한의 80% 이상
  overLimit, // 합산이 상한 이상
}

/// 한 영양소의 활성 영양제 전반에 대한 합산·중복 판정 결과.
class NutrientStatus {
  final String key;
  final String label;
  final int productCount; // 이 성분을 가진 활성 영양제 수
  final double? totalInBase; // 합산 함량(baseUnit). 일부라도 미상이면 null
  final double? ulPercent; // 상한 대비 %(상한·합산이 모두 있을 때만)
  final NutrientLevel level;
  final bool highRisk;

  const NutrientStatus({
    required this.key,
    required this.label,
    required this.productCount,
    required this.totalInBase,
    required this.ulPercent,
    required this.level,
    required this.highRisk,
  });

  bool get isOverLimit => level == NutrientLevel.overLimit;
}

/// 함량을 기준 단위(mg/ug)로 변환. IU는 성분별 통용 환산을 best-effort 적용.
/// 변환 불가(단위 불명 등)면 null.
double? _toBase(NutrientAmount n, NutrientRef ref) {
  final amount = n.amount;
  final unit = n.unit;
  if (amount == null || unit == null) return null;

  // mg↔ug 정규화
  double? asMg;
  double? asUg;
  switch (unit) {
    case 'mg':
      asMg = amount;
      asUg = amount * 1000;
      break;
    case 'ug':
      asMg = amount / 1000;
      asUg = amount;
      break;
    case 'IU':
      // 성분별 IU 환산 (대표 표준치)
      switch (n.key) {
        case 'vitamin_a':
          asUg = amount * 0.3; // 1 IU 레티놀 ≈ 0.3 µg RAE
          asMg = asUg / 1000;
          break;
        case 'vitamin_d':
          asUg = amount * 0.025; // 1 IU ≈ 0.025 µg
          asMg = asUg / 1000;
          break;
        case 'vitamin_e':
          asMg = amount * 0.67; // 1 IU ≈ 0.67 mg
          asUg = asMg * 1000;
          break;
        default:
          return null; // 그 외 성분은 IU 환산 미정의
      }
      break;
    default:
      return null;
  }
  return ref.baseUnit == 'mg' ? asMg : asUg;
}

/// 활성 영양제 목록을 받아 노출할 가치가 있는(ok 제외) 영양소 상태를
/// 위험도 순으로 반환. 중복·상한 경고 카드/상세에서 그대로 쓴다.
List<NutrientStatus> analyzeNutrients(List<Supplement> supplements) {
  // key → (제품 수, 합산값, 합산 완전성)
  final counts = <String, int>{};
  final totals = <String, double>{};
  final complete = <String, bool>{}; // 모든 함량을 읽었는가

  for (final s in supplements) {
    // 한 제품에 같은 키가 중복 표기될 수 있어 제품 단위로 집계
    final seen = <String>{};
    for (final n in s.nutrients) {
      final ref = kNutrients[n.key];
      if (ref == null) continue;
      if (seen.add(n.key)) {
        counts[n.key] = (counts[n.key] ?? 0) + 1;
      }
      complete.putIfAbsent(n.key, () => true);
      final base = _toBase(n, ref);
      if (base == null) {
        complete[n.key] = false;
      } else {
        totals[n.key] = (totals[n.key] ?? 0) + base;
      }
    }
  }

  final result = <NutrientStatus>[];
  counts.forEach((key, count) {
    final ref = kNutrients[key]!;
    final isComplete = complete[key] ?? false;
    final total = isComplete ? totals[key] : null;
    final ulPercent =
        (ref.ul != null && total != null) ? total / ref.ul! * 100 : null;

    NutrientLevel level;
    if (ulPercent != null && ulPercent >= 100) {
      level = NutrientLevel.overLimit;
    } else if (ulPercent != null && ulPercent >= 80) {
      level = NutrientLevel.nearLimit;
    } else if (count >= 2) {
      level = NutrientLevel.overlap;
    } else {
      level = NutrientLevel.ok;
    }
    if (level == NutrientLevel.ok) return;

    result.add(NutrientStatus(
      key: key,
      label: ref.label,
      productCount: count,
      totalInBase: total,
      ulPercent: ulPercent,
      level: level,
      highRisk: ref.highRisk,
    ));
  });

  // 위험도(상한근접 > 중복) → 고위험 성분 → %UL 순으로 정렬
  int rank(NutrientLevel l) => switch (l) {
        NutrientLevel.overLimit => 0,
        NutrientLevel.nearLimit => 1,
        NutrientLevel.overlap => 2,
        NutrientLevel.ok => 3,
      };
  result.sort((a, b) {
    final r = rank(a.level).compareTo(rank(b.level));
    if (r != 0) return r;
    if (a.highRisk != b.highRisk) return a.highRisk ? -1 : 1;
    return (b.ulPercent ?? 0).compareTo(a.ulPercent ?? 0);
  });
  return result;
}
