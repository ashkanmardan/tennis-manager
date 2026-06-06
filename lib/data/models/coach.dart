class Coach {
  final int? id;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  const Coach({
    this.id,
    required this.name,
    this.phone,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'notes': notes,
      };

  factory Coach.fromMap(Map<String, dynamic> map) => Coach(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        isActive: map['is_active'] == 1,
        startDate: DateTime.parse(map['start_date']),
        endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
        notes: map['notes'],
      );

  Coach copyWith({
    int? id,
    String? name,
    String? phone,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) =>
      Coach(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        isActive: isActive ?? this.isActive,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        notes: notes ?? this.notes,
      );
}
