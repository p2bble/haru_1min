class Supplement {
  final int? id;
  final String name;
  final String? imagePath;
  final String mealTime; // morning, lunch, dinner, bedtime
  final bool isActive;
  final DateTime createdAt;

  const Supplement({
    this.id,
    required this.name,
    this.imagePath,
    required this.mealTime,
    this.isActive = true,
    required this.createdAt,
  });

  Supplement copyWith({
    int? id,
    String? name,
    String? imagePath,
    String? mealTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Supplement(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      mealTime: mealTime ?? this.mealTime,
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
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
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
