import 'dart:convert';

class Player {
  final int? id;
  final String name;
  final String? birthDate;
  final String? phone;
  final String coachName;
  final String? coachPhone;
  final String? coachInstagram;
  final String? coachCardNumber;
  final String? clubName;
  final String trainingDays;
  final String trainingTime;
  final int    sessionDuration;
  final int    classParticipants; // تعداد نفرات کلاس (۱-۶)
  final bool   onboardingComplete;

  const Player({
    this.id,
    required this.name,
    this.birthDate,
    this.phone,
    required this.coachName,
    this.coachPhone,
    this.coachInstagram,
    this.coachCardNumber,
    this.clubName,
    required this.trainingDays,
    required this.trainingTime,
    this.sessionDuration = 60,
    this.classParticipants = 1,
    this.onboardingComplete = false,
  });

  List<String> get trainingDaysList {
    if (trainingDays == 'odd' || trainingDays == 'even') return [trainingDays];
    try { return List<String>.from(jsonDecode(trainingDays) as List); }
    catch (_) { return []; }
  }

  String get trainingDaysLabel {
    if (trainingDays == 'odd')  return 'روزهای فرد';
    if (trainingDays == 'even') return 'روزهای زوج';
    final days = trainingDaysList;
    const map = {
      'sat':'شنبه','sun':'یکشنبه','mon':'دوشنبه',
      'tue':'سه‌شنبه','wed':'چهارشنبه','thu':'پنجشنبه','fri':'جمعه',
    };
    return days.map((d) => map[d] ?? d).join('، ');
  }

  Map<String, dynamic> toMap() => {
    'id': 1,
    'name': name,
    'birth_date': birthDate,
    'phone': phone,
    'coach_name': coachName,
    'coach_phone': coachPhone,
    'coach_instagram': coachInstagram,
    'coach_card_number': coachCardNumber,
    'club_name': clubName,
    'training_days': trainingDays,
    'training_time': trainingTime,
    'session_duration': sessionDuration,
    'class_participants': classParticipants,
    'onboarding_complete': onboardingComplete ? 1 : 0,
  };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    birthDate: m['birth_date'] as String?,
    phone: m['phone'] as String?,
    coachName: m['coach_name'] as String? ?? '',
    coachPhone: m['coach_phone'] as String?,
    coachInstagram: m['coach_instagram'] as String?,
    coachCardNumber: m['coach_card_number'] as String?,
    clubName: m['club_name'] as String?,
    trainingDays: m['training_days'] as String? ?? '[]',
    trainingTime: m['training_time'] as String? ?? '17:00',
    sessionDuration: m['session_duration'] as int? ?? 60,
    classParticipants: m['class_participants'] as int? ?? 1,
    onboardingComplete: (m['onboarding_complete'] as int? ?? 0) == 1,
  );

  Player copyWith({
    String? name, String? birthDate, String? phone,
    String? coachName, String? coachPhone, String? coachInstagram,
    String? coachCardNumber, String? clubName,
    String? trainingDays, String? trainingTime,
    int? sessionDuration, int? classParticipants, bool? onboardingComplete,
  }) => Player(
    id: id,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    phone: phone ?? this.phone,
    coachName: coachName ?? this.coachName,
    coachPhone: coachPhone ?? this.coachPhone,
    coachInstagram: coachInstagram ?? this.coachInstagram,
    coachCardNumber: coachCardNumber ?? this.coachCardNumber,
    clubName: clubName ?? this.clubName,
    trainingDays: trainingDays ?? this.trainingDays,
    trainingTime: trainingTime ?? this.trainingTime,
    sessionDuration: sessionDuration ?? this.sessionDuration,
    classParticipants: classParticipants ?? this.classParticipants,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}
