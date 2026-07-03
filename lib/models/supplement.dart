import 'dart:convert';

/// 라벨에서 읽은 영양소 1정당 함량. [amount]/[unit]은 표(영양·기능정보)를
/// 못 읽으면 null — 그래도 [key]만 있으면 "중복" 판정에는 쓸 수 있다.
class NutrientAmount {
  final String key; // nutrient_info.kNutrients의 표준 키
  final double? amount; // 1정당 함량
  final String? unit; // mg / ug / IU

  const NutrientAmount({required this.key, this.amount, this.unit});

  Map<String, dynamic> toJson() => {
        'key': key,
        if (amount != null) 'amount': amount,
        if (unit != null) 'unit': unit,
      };

  factory NutrientAmount.fromJson(Map<String, dynamic> json) => NutrientAmount(
        key: json['key'] as String,
        amount: (json['amount'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
      );
}

class Supplement {
  final int? id;
  final String name;
  final String? imagePath;
  final String mealTime; // morning, lunch, dinner, bedtime
  final String? memo; // 복용 팁 (AI 분석 결과 또는 직접 입력)
  final List<NutrientAmount> nutrients; // AI가 라벨에서 추출한 성분 (중복 분석용)
  final bool isActive;
  final DateTime createdAt;

  const Supplement({
    this.id,
    required this.name,
    this.imagePath,
    required this.mealTime,
    this.memo,
    this.nutrients = const [],
    this.isActive = true,
    required this.createdAt,
  });

  // nullable 필드(imagePath/memo)는 "미지정"과 "null로 지움"을 구분해야 한다.
  // `?? this.x` 방식이면 null을 넘겨도 기존 값이 남아 삭제가 불가능해진다.
  static const _unset = Object();

  Supplement copyWith({
    int? id,
    String? name,
    Object? imagePath = _unset,
    String? mealTime,
    Object? memo = _unset,
    List<NutrientAmount>? nutrients,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath:
          identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      mealTime: mealTime ?? this.mealTime,
      memo: identical(memo, _unset) ? this.memo : memo as String?,
      nutrients: nutrients ?? this.nutrients,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'mealTime': mealTime,
      'memo': memo,
      'nutrients': nutrients.isEmpty
          ? null
          : jsonEncode(nutrients.map((n) => n.toJson()).toList()),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      mealTime: map['mealTime'],
      memo: map['memo'],
      nutrients: _decodeNutrients(map['nutrients'] as String?),
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  static List<NutrientAmount> _decodeNutrients(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => NutrientAmount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class SupplementLog {
  final int? id;
  final int supplementId;
  final DateTime takenAt;

  const SupplementLog({
    this.id,
    required this.supplementId,
    required this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplementId': supplementId,
      'takenAt': takenAt.toIso8601String(),
    };
  }

  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'],
      supplementId: map['supplementId'],
      takenAt: DateTime.parse(map['takenAt']),
    );
  }
}

const mealTimeLabels = {
  'morning': '아침',
  'lunch': '점심',
  'dinner': '저녁',
  'bedtime': '자기 전',
};
