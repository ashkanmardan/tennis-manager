class Payment {
  final int? id;
  final int studentId;
  final int amount;
  final DateTime date;
  final String? description;
  final String? receiptImagePath; // path to receipt image
  final String? receiptNote;
  final int? sessionId; // if payment is for specific session
  final String paymentFor; // 'tuition' | 'ball_cost' | 'other'
  final DateTime createdAt;

  const Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.date,
    this.description,
    this.receiptImagePath,
    this.receiptNote,
    this.sessionId,
    this.paymentFor = 'tuition',
    required this.createdAt,
  });

  bool get hasReceipt => receiptImagePath != null || receiptNote != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'receipt_image_path': receiptImagePath,
        'receipt_note': receiptNote,
        'session_id': sessionId,
        'payment_for': paymentFor,
        'created_at': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'],
        studentId: map['student_id'],
        amount: map['amount'],
        date: DateTime.parse(map['date']),
        description: map['description'],
        receiptImagePath: map['receipt_image_path'],
        receiptNote: map['receipt_note'],
        sessionId: map['session_id'],
        paymentFor: map['payment_for'] ?? 'tuition',
        createdAt: DateTime.parse(map['created_at']),
      );

  Payment copyWith({
    int? id,
    int? studentId,
    int? amount,
    DateTime? date,
    String? description,
    String? receiptImagePath,
    String? receiptNote,
    int? sessionId,
    String? paymentFor,
    DateTime? createdAt,
  }) =>
      Payment(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        description: description ?? this.description,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
        receiptNote: receiptNote ?? this.receiptNote,
        sessionId: sessionId ?? this.sessionId,
        paymentFor: paymentFor ?? this.paymentFor,
        createdAt: createdAt ?? this.createdAt,
      );
}
