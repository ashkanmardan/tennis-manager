import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/app_repository.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await context.read<AppRepository>().getAllPayments();
    if (mounted) setState(() { _payments = payments; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final totalThisMonth = _payments.where((p) {
      final j = JalaliHelper.today;
      return JalaliHelper.isSameJalaliMonth(
        p.date,
        JalaliHelper.toDateTime(j.year, j.month, 1),
      );
    }).fold(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت‌ها')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('درآمد ماه جاری',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            '${JalaliHelper.formatAmount(totalThisMonth)} تومان',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _payments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('پرداختی ثبت نشده',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _payments.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (ctx, i) {
                            final payment = _payments[i];
                            final matched = repo.students
                                .where((s) => s.id == payment.studentId)
                                .toList();
                            final student = matched.isNotEmpty ? matched.first : null;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade50,
                                  child: const Icon(Icons.attach_money, color: Colors.green),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student?.name ?? 'نامشخص',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      '${JalaliHelper.formatAmount(payment.amount)} ت',
                                      style: const TextStyle(
                                          color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(JalaliHelper.formatDate(payment.date)),
                                    if (payment.description != null) ...[
                                      const Text(' · '),
                                      Expanded(
                                        child: Text(
                                          payment.description!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: payment.hasReceipt
                                    ? const Icon(Icons.receipt, color: Colors.blue, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPayment(context, repo.activeStudents),
        icon: const Icon(Icons.add),
        label: const Text('پرداخت جدید'),
      ),
    );
  }

  void _addPayment(BuildContext context, List<Student> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPaymentSheet(students: students, onSaved: _loadPayments),
    );
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final List<Student> students;
  final VoidCallback onSaved;

  const _AddPaymentSheet({required this.students, required this.onSaved});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Student? _selectedStudent;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedStudent == null) return;
    setState(() => _saving = true);
    try {
      final payment = Payment(
        studentId: _selectedStudent!.id!,
        amount: int.parse(_amountCtrl.text.replaceAll(',', '')),
        date: DateTime.now(),
        description: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        createdAt: DateTime.now(),
      );
      await context.read<AppRepository>().addPayment(payment);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ثبت پرداخت',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<Student>(
              value: _selectedStudent,
              decoration: const InputDecoration(
                labelText: 'انتخاب شاگرد *',
                prefixIcon: Icon(Icons.person),
              ),
              items: widget.students.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedStudent = v),
              validator: (v) => v == null ? 'شاگرد را انتخاب کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان) *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'مبلغ الزامی است' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ثبت پرداخت'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
