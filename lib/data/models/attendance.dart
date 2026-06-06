class Attendance {
  final int? id;
  final int sessionId;
  final int studentId;
  final bool present;
  final bool isMakeupFor; // این حضور، جبرانی برای جلسه دیگری‌ست
  final int? makeupForSessionId;
  final String? notes;

  const Attendance({
    this.id,
    required this.sessionId,
    required this.studentId,
    this.present = true,
    this.isMakeupFor = false,
    this.makeupForSessionId,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'present': present ? 1 : 0,
        'is_makeup_for': isMakeupFor ? 1 : 0,
        'makeup_for_session_id': makeupForSessionId,
        'notes': notes,
      };

  factory Attendance.fromMap(Map<String, dynamic> map) => Attendance(
        id: map['id'],
        sessionId: map['session_id'],
        studentId: map['student_id'],
        present: map['present'] == 1,
        isMakeupFor: map['is_makeup_for'] == 1,
        makeupForSessionId: map['makeup_for_session_id'],
        notes: map['notes'],
      );
}
