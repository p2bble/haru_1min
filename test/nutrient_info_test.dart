import 'package:flutter_test/flutter_test.dart';
import 'package:haru_1min/models/supplement.dart';
import 'package:haru_1min/services/nutrient_info.dart';

Supplement _supp(String name, List<NutrientAmount> nutrients) => Supplement(
      name: name,
      mealTime: 'morning',
      nutrients: nutrients,
      createdAt: DateTime(2026, 6, 28),
    );

void main() {
  group('analyzeNutrients', () {
    test('단일 제품·상한 여유면 노출하지 않는다(ok 제외)', () {
      final r = analyzeNutrients([
        _supp('A', [const NutrientAmount(key: 'zinc', amount: 5, unit: 'mg')]),
      ]);
      expect(r, isEmpty);
    });

    test('두 제품에 같은 성분이 있으면 overlap으로 잡는다(함량 미상)', () {
      final r = analyzeNutrients([
        _supp('A', [const NutrientAmount(key: 'zinc')]),
        _supp('B', [const NutrientAmount(key: 'zinc')]),
      ]);
      expect(r, hasLength(1));
      expect(r.first.key, 'zinc');
      expect(r.first.productCount, 2);
      expect(r.first.level, NutrientLevel.overlap);
      expect(r.first.ulPercent, isNull); // 함량 미상이라 %UL 없음
    });

    test('합산이 상한을 넘으면 overLimit (아연 UL 35mg)', () {
      final r = analyzeNutrients([
        _supp('A', [const NutrientAmount(key: 'zinc', amount: 20, unit: 'mg')]),
        _supp('B', [const NutrientAmount(key: 'zinc', amount: 20, unit: 'mg')]),
      ]);
      expect(r.first.level, NutrientLevel.overLimit);
      expect(r.first.ulPercent, closeTo(114.3, 0.5)); // 40/35
    });

    test('합산이 상한의 80~99%면 nearLimit', () {
      final r = analyzeNutrients([
        _supp('A', [const NutrientAmount(key: 'zinc', amount: 30, unit: 'mg')]),
      ]);
      expect(r.first.level, NutrientLevel.nearLimit); // 30/35 ≈ 86%
    });

    test('IU 환산: 비타민D 5000IU = 125ug > UL 100ug → overLimit', () {
      final r = analyzeNutrients([
        _supp('A',
            [const NutrientAmount(key: 'vitamin_d', amount: 5000, unit: 'IU')]),
      ]);
      expect(r.first.key, 'vitamin_d');
      expect(r.first.level, NutrientLevel.overLimit);
    });

    test('mg↔ug 정규화: 칼슘 1000mg + 1500000ug = 2500mg = UL 100%', () {
      final r = analyzeNutrients([
        _supp('A',
            [const NutrientAmount(key: 'calcium', amount: 1000, unit: 'mg')]),
        _supp('B', [
          const NutrientAmount(key: 'calcium', amount: 1500000, unit: 'ug')
        ]),
      ]);
      expect(r.first.level, NutrientLevel.overLimit); // 정확히 100%
      expect(r.first.ulPercent, closeTo(100, 0.1));
    });

    test('한 제품 내 같은 키 중복은 제품 1개로만 센다', () {
      final r = analyzeNutrients([
        _supp('A', [
          const NutrientAmount(key: 'zinc'),
          const NutrientAmount(key: 'zinc'),
        ]),
      ]);
      expect(r, isEmpty); // 제품 수 1 → overlap 아님
    });

    test('위험도 정렬: overLimit이 overlap보다 앞', () {
      final r = analyzeNutrients([
        _supp('A', [
          const NutrientAmount(key: 'iron', amount: 30, unit: 'mg'), // 과량
          const NutrientAmount(key: 'vitamin_c'),
        ]),
        _supp('B', [
          const NutrientAmount(key: 'iron', amount: 30, unit: 'mg'),
          const NutrientAmount(key: 'vitamin_c'),
        ]),
      ]);
      expect(r.first.key, 'iron'); // 60/45 overLimit
      expect(r.first.level, NutrientLevel.overLimit);
      expect(r.last.key, 'vitamin_c'); // overlap
      expect(r.last.level, NutrientLevel.overlap);
    });

    test('알 수 없는 키는 무시한다', () {
      final r = analyzeNutrients([
        _supp('A', [const NutrientAmount(key: 'unknown_x')]),
        _supp('B', [const NutrientAmount(key: 'unknown_x')]),
      ]);
      expect(r, isEmpty);
    });
  });
}
