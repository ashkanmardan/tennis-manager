class TrainingPackage {
  final int?   id;
  final String name;
  final int    totalSessions;
  final int    price;          // تومان
  final String startDate;      // Jalali YYYY-MM-DD
  final bool   isActive;
  final String createdAt;

  // runtime-populated (not stored in DB)
  final int completedSessions;
  final int paidAmount;

  const TrainingPackage({
    this.id,
    required this.name,
    required this.totalSessions,
    required this.price,
    required this.startDate,
    this.isActive = true,
    required this.createdAt,
    this.completedSessions = 0,
    this.paidAmount = 0,
  });

  int get remainingSessions => (totalSessions - completedSessions).clamp(0, totalSessions);
  int get debt => (price - paidAmount).clamp(0, price);
  double get progressFraction => totalSessions == 0 ? 0 : completedSessions / totalSessions;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'total_sessions': totalSessions,
    'price': price,
    'start_date': startDate,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
  };

  factory TrainingPackage.fromMap(Map<String, dynamic> m) => TrainingPackage(
    id: m['id'] as int?,
    name: m['name'] as String,
    totalSessions: m['total_sessions'] as int,
    price: m['price'] as int,
    startDate: m['start_date'] as String,
    isActive: (m['is_active'] as int? ?? 1) == 1,
    createdAt: m['created_at'] as String,
    completedSessions: m['completed_sessions'] as int? ?? 0,
    paidAmount: m['paid_amount'] as int? ?? 0,
  );

  TrainingPackage copyWith({
    String? name, int? totalSessions, int? price, String? startDate,
    bool? isActive, int? completedSessions, int? paidAmount,
  }) => TrainingPackage(
    id: id,
    name: name ?? this.name,
    totalSessions: totalSessions ?? this.totalSessions,
    price: price ?? this.price,
    startDate: startDate ?? this.startDate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    completedSessions: completedSessions ?? this.completedSessions,
    paidAmount: paidAmount ?? this.paidAmount,
  );
}
