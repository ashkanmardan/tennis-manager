class Student {
  final int? id;
  final String name;
  final String? phone;
  final String feeType; // 'monthly' | 'session'
  final int feeAmount;
  final bool isActive;
  final DateTime createdAt;
  final String? notes;

  const Student({
    this.id,
    required this.name,
    this.phone,
    required this.feeType,
    required this.feeAmount,
    this.isActive = true,
    required this.createdAt,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'fee_type': feeType,
        'fee_amount': feeAmount,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        feeType: map['fee_type'],
        feeAmount: map['fee_amount'],
        isActive: map['is_active'] == 1,
        createdAt: DateTime.parse(map['created_at']),
        notes: map['notes'],
      );

  Student copyWith({
    int? id,
    String? name,
    String? phone,
    String? feeType,
    int? feeAmount,
    bool? isActive,
    DateTime? createdAt,
    String? notes,
  }) =>
      Student(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        feeType: feeType ?? this.feeType,
        feeAmount: feeAmount ?? this.feeAmount,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        notes: notes ?? this.notes,
      );
}
