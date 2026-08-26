class Payment {
  final int?   id;
  final int    amount;
  final String paymentDate;
  final int?   packageId;
  final String? notes;
  final String? receiptImagePath;
  final String createdAt;

  const Payment({
    this.id,
    required this.amount,
    required this.paymentDate,
    this.packageId,
    this.notes,
    this.receiptImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'amount': amount,
    'payment_date': paymentDate,
    'package_id': packageId,
    'notes': notes,
    'receipt_image_path': receiptImagePath,
    'created_at': createdAt,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] as int?,
    amount: m['amount'] as int,
    paymentDate: m['payment_date'] as String,
    packageId: m['package_id'] as int?,
    notes: m['notes'] as String?,
    receiptImagePath: m['receipt_image_path'] as String?,
    createdAt: m['created_at'] as String,
  );
}
