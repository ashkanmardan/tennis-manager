enum SessionStatus {
  upcoming,           // پیش رو
  completed,          // برگزار شد
  cancelledByCoach,   // لغو مربی → جبرانی ایجاد می‌شود
  cancelledByPlayer,  // لغو بازیکن → می‌سوزد
  weather,            // باران / آب‌وهوا → جبرانی ایجاد می‌شود
  holiday,            // تعطیل رسمی → نیاز به تغییر تاریخ
  rescheduled,        // تغییر تاریخ داده شد
}

extension SessionStatusX on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.upcoming:          return 'پیش رو';
      case SessionStatus.completed:         return 'برگزار شد';
      case SessionStatus.cancelledByCoach:  return 'لغو توسط مربی';
      case SessionStatus.cancelledByPlayer: return 'لغو توسط بازیکن';
      case SessionStatus.weather:           return 'لغو آب‌وهوایی';
      case SessionStatus.holiday:           return 'تعطیل رسمی';
      case SessionStatus.rescheduled:       return 'تغییر تاریخ';
    }
  }

  String get emoji {
    switch (this) {
      case SessionStatus.upcoming:          return '🗓';
      case SessionStatus.completed:         return '✅';
      case SessionStatus.cancelledByCoach:  return '❌';
      case SessionStatus.cancelledByPlayer: return '🚫';
      case SessionStatus.weather:           return '🌧';
      case SessionStatus.holiday:           return '📅';
      case SessionStatus.rescheduled:       return '🔄';
    }
  }

  bool get createsMakeup =>
      this == SessionStatus.cancelledByCoach ||
      this == SessionStatus.weather;

  String toDb() => name;

  static SessionStatus fromDb(String s) =>
      SessionStatus.values.firstWhere((e) => e.name == s,
          orElse: () => SessionStatus.upcoming);
}

class Session {
  final int?          id;
  final String        scheduledDate;   // ISO YYYY-MM-DD
  final int           jalaliYear;
  final int           jalaliMonth;
  final String?       time;            // HH:MM
  final int           duration;
  final SessionStatus status;
  final String?       notes;
  final int?          packageId;
  final bool          isMakeup;
  final int?          makeupForSessionId;
  final String        createdAt;

  const Session({
    this.id,
    required this.scheduledDate,
    required this.jalaliYear,
    required this.jalaliMonth,
    this.time,
    this.duration = 60,
    this.status = SessionStatus.upcoming,
    this.notes,
    this.packageId,
    this.isMakeup = false,
    this.makeupForSessionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'scheduled_date': scheduledDate,
    'jalali_year': jalaliYear,
    'jalali_month': jalaliMonth,
    'time': time,
    'duration': duration,
    'status': status.toDb(),
    'notes': notes,
    'package_id': packageId,
    'is_makeup': isMakeup ? 1 : 0,
    'makeup_for_session_id': makeupForSessionId,
    'created_at': createdAt,
  };

  factory Session.fromMap(Map<String, dynamic> m) => Session(
    id: m['id'] as int?,
    scheduledDate: m['scheduled_date'] as String,
    jalaliYear: m['jalali_year'] as int,
    jalaliMonth: m['jalali_month'] as int,
    time: m['time'] as String?,
    duration: m['duration'] as int? ?? 60,
    status: SessionStatusX.fromDb(m['status'] as String? ?? 'upcoming'),
    notes: m['notes'] as String?,
    packageId: m['package_id'] as int?,
    isMakeup: (m['is_makeup'] as int? ?? 0) == 1,
    makeupForSessionId: m['makeup_for_session_id'] as int?,
    createdAt: m['created_at'] as String,
  );

  Session copyWith({
    String? scheduledDate, int? jalaliYear, int? jalaliMonth,
    String? time, int? duration, SessionStatus? status,
    String? notes, int? packageId, bool? isMakeup, int? makeupForSessionId,
  }) => Session(
    id: id,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    jalaliYear: jalaliYear ?? this.jalaliYear,
    jalaliMonth: jalaliMonth ?? this.jalaliMonth,
    time: time ?? this.time,
    duration: duration ?? this.duration,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    packageId: packageId ?? this.packageId,
    isMakeup: isMakeup ?? this.isMakeup,
    makeupForSessionId: makeupForSessionId ?? this.makeupForSessionId,
    createdAt: createdAt,
  );
}
