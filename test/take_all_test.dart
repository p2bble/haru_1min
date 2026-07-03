import 'package:flutter_test/flutter_test.dart';

/// takeAll의 핵심 규칙만 순수 함수로 추출해 검증한다.
/// (StateNotifier는 DB에 의존하므로, 여기서는 "무엇을 새로 복용 처리할지"
///  결정하는 로직 — 이미 먹은 건 제외 — 만 떼어 테스트한다.)
Set<int> resolveNewlyTaken(Set<int> current, Iterable<int> all) {
  final toTake = all.where((id) => !current.contains(id)).toList();
  return {...current, ...toTake};
}

void main() {
  group('시간대 모두 체크', () {
    test('아무것도 안 먹었으면 전체가 복용 처리된다', () {
      expect(resolveNewlyTaken({}, [1, 2, 3]), {1, 2, 3});
    });

    test('이미 먹은 건 유지하고 나머지만 추가한다', () {
      expect(resolveNewlyTaken({2}, [1, 2, 3]), {1, 2, 3});
    });

    test('모두 이미 먹었으면 변화 없다', () {
      expect(resolveNewlyTaken({1, 2}, [1, 2]), {1, 2});
    });

    test('다른 시간대의 복용 상태는 건드리지 않는다', () {
      // 9는 다른 시간대에서 이미 먹은 영양제 — 아침 [1,2] 모두 체크해도 유지
      expect(resolveNewlyTaken({9}, [1, 2]), {9, 1, 2});
    });
  });
}
