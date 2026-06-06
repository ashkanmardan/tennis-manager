class BallCost {
  final int? id;
  final DateTime date;
  final int totalCost;
  final int? sessionId;
  final String? notes;
  final DateTime createdAt;

  const BallCost({
    this.id,
    required this.date,
    required this.totalCost,
    this.sessionId,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'total_cost': totalCost,
        'session_id': sessionId,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory BallCost.fromMap(Map<String, dynamic> map) => BallCost(
        id: map['id'],
        date: DateTime.parse(map['date']),
        totalCost: map['total_cost'],
        sessionId: map['session_id'],
        notes: map['notes'],
        createdAt: DateTime.parse(map['created_at']),
      );
}
