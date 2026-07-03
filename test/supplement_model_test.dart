import 'package:flutter_test/flutter_test.dart';
import 'package:haru_1min/models/supplement.dart';

void main() {
  final base = Supplement(
    id: 1,
    name: '비타민C',
    imagePath: '/images/a.jpg',
    mealTime: 'morning',
    memo: '식후 복용',
    createdAt: DateTime(2026, 1, 1),
  );

  group('Supplement.copyWith', () {
    test('미지정 필드는 기존 값을 유지한다', () {
      final copy = base.copyWith(name: '비타민D');
      expect(copy.name, '비타민D');
      expect(copy.memo, '식후 복용');
      expect(copy.imagePath, '/images/a.jpg');
      expect(copy.mealTime, 'morning');
    });

    test('memo에 null을 넘기면 실제로 지워진다 (수정 화면에서 팁 삭제)', () {
      final copy = base.copyWith(memo: null);
      expect(copy.memo, isNull);
    });

    test('imagePath에 null을 넘기면 실제로 지워진다', () {
      final copy = base.copyWith(imagePath: null);
      expect(copy.imagePath, isNull);
    });

    test('memo를 새 값으로 교체할 수 있다', () {
      final copy = base.copyWith(memo: '공복 복용');
      expect(copy.memo, '공복 복용');
    });
  });

  group('Supplement 직렬화', () {
    test('toMap → fromMap 왕복이 값을 보존한다', () {
      final s = base.copyWith(nutrients: [
        const NutrientAmount(key: 'vitamin_c', amount: 500, unit: 'mg'),
        const NutrientAmount(key: 'zinc'),
      ]);
      final restored = Supplement.fromMap(s.toMap());
      expect(restored.name, s.name);
      expect(restored.memo, s.memo);
      expect(restored.mealTime, s.mealTime);
      expect(restored.nutrients.length, 2);
      expect(restored.nutrients[0].key, 'vitamin_c');
      expect(restored.nutrients[0].amount, 500);
      expect(restored.nutrients[1].amount, isNull);
    });

    test('손상된 nutrients JSON은 빈 목록으로 복구한다', () {
      final map = base.toMap()..['nutrients'] = '{broken';
      expect(Supplement.fromMap(map).nutrients, isEmpty);
    });
  });
}
