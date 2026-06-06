class Session {
  final int? id;
  final DateTime date;
  final String sessionType; // 'regular' | 'makeup'
  final int? coachId;
  final String? venue;
  final bool coachCancelled; // true = cancelled by coach
  final bool requiresMakeup;  // coach cancellation needs makeup
  final int? originalSessionId; // for makeup: points to session being compensated
  final String? notes;
  final DateTime createdAt;

  const Session({
    this.id,
    required this.date,
    this.sessionType = 'regular',
    this.coachId,
    this.venue,
    this.coachCancelled = false,
    this.requiresMakeup = false,
    this.originalSessionId,
    this.notes,
    required this.createdAt,
  });

  bool get isMakeup => sessionType == 'makeup';
  bool get isRegular => sessionType == 'regular';

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'session_type': sessionType,
        'coach_id': coachId,
        'venue': venue,
        'coach_cancelled': coachCancelled ? 1 : 0,
        'requires_makeup': requiresMakeup ? 1 : 0,
        'original_session_id': originalSessionId,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'],
        date: DateTime.parse(map['date']),
        sessionType: map['session_type'] ?? 'regular',
        coachId: map['coach_id'],
        venue: map['venue'],
        coachCancelled: map['coach_cancelled'] == 1,
        requiresMakeup: map['requires_makeup'] == 1,
        originalSessionId: map['original_session_id'],
        notes: map['notes'],
        createdAt: DateTime.parse(map['created_at']),
      );

  Session copyWith({
    int? id,
    DateTime? date,
    String? sessionType,
    int? coachId,
    String? venue,
    bool? coachCancelled,
    bool? requiresMakeup,
    int? originalSessionId,
    String? notes,
    DateTime? createdAt,
  }) =>
      Session(
        id: id ?? this.id,
        date: date ?? this.date,
        sessionType: sessionType ?? this.sessionType,
        coachId: coachId ?? this.coachId,
        venue: venue ?? this.venue,
        coachCancelled: coachCancelled ?? this.coachCancelled,
        requiresMakeup: requiresMakeup ?? this.requiresMakeup,
        originalSessionId: originalSessionId ?? this.originalSessionId,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
}
