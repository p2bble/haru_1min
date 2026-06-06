class WaterLog {
  final int? id;
  final int amount; // ml
  final DateTime loggedAt;

  const WaterLog({
    this.id,
    required this.amount,
    required this.loggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'],
      amount: map['amount'],
      loggedAt: DateTime.parse(map['loggedAt']),
    );
  }
}
