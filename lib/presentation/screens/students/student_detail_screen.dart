import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/student.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/attendance.dart';
import '../../../data/repositories/app_repository.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _payments = [];
  List<Attendance> _attendance = [];
  int _debt = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<AppRepository>();
    final results = await Future.wait([
      repo.getPaymentsForStudent(widget.student.id!),
      repo.getAttendanceForStudent(widget.student.id!),
      repo.getStudentDebt(widget.student),
    ]);
    if (mounted) {
      setState(() {
        _payments = results[0] as List<Payment>;
        _attendance = results[1] as List<Attendance>;
        _debt = results[2] as int;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editStudent(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'اطلاعات'),
            Tab(text: 'پرداخت‌ها'),
            Tab(text: 'حضور/غیاب'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(student: student, debt: _debt),
                _PaymentsTab(payments: _payments, student: student, onRefresh: _loadData),
                _AttendanceTab(attendance: _attendance),
              ],
            ),
    );
  }

  void _editStudent(BuildContext context) {
    // TODO: Edit student sheet
  }
}

class _InfoTab extends StatelessWidget {
  final Student student;
  final int debt;

  const _InfoTab({required this.student, required this.debt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Debt status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: debt > 0 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: debt > 0 ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                debt > 0 ? Icons.warning_amber : Icons.check_circle,
                color: debt > 0 ? Colors.red : Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt > 0 ? 'بدهکار' : 'تسویه‌شده',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: debt > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  if (debt > 0)
                    Text(
                      '${JalaliHelper.formatAmount(debt)} تومان',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const Spacer(),
              if (debt > 0)
                ElevatedButton(
                  onPressed: () {
                    // Quick payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('پرداخت', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _InfoRow(icon: Icons.person, label: 'نام', value: student.name),
        if (student.phone != null)
          _InfoRow(icon: Icons.phone, label: 'تلفن', value: student.phone!),
        _InfoRow(
          icon: Icons.monetization_on,
          label: 'نوع شهریه',
          value: student.feeType == AppConstants.feeTypeMonthly ? 'ماهانه' : 'جلسه‌ای',
        ),
        _InfoRow(
          icon: Icons.attach_money,
          label: 'مبلغ شهریه',
          value: '${JalaliHelper.formatAmount(student.feeAmount)} تومان',
        ),
        _InfoRow(
          icon: Icons.calendar_today,
          label: 'تاریخ ثبت‌نام',
          value: JalaliHelper.formatDateLong(student.createdAt),
        ),
        if (student.notes != null && student.notes!.isNotEmpty)
          _InfoRow(icon: Icons.notes, label: 'یادداشت', value: student.notes!),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final Student student;
  final VoidCallback onRefresh;

  const _PaymentsTab({
    required this.payments,
    required this.student,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final total = payments.fold(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF2E7D32).withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('مجموع پرداختی: ${JalaliHelper.formatAmount(total)} تومان',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _addPayment(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('پرداخت جدید'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? const Center(child: Text('پرداختی ثبت نشده', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: payments.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (ctx, i) {
                    final p = payments[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.attach_money, color: Colors.green),
                        ),
                        title: Text('${JalaliHelper.formatAmount(p.amount)} تومان'),
                        subtitle: Text(JalaliHelper.formatDateLong(p.date)),
                        trailing: p.hasReceipt
                            ? const Icon(Icons.receipt, color: Colors.blue, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPaymentSheet(student: student, onSaved: onRefresh),
    );
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final Student student;
  final VoidCallback onSaved;

  const _AddPaymentSheet({required this.student, required this.onSaved});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payment = Payment(
        studentId: widget.student.id!,
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
            Text('ثبت پرداخت — ${widget.student.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
                    : const Text('ذخیره پرداخت'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final List<Attendance> attendance;

  const _AttendanceTab({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final present = attendance.where((a) => a.present).length;
    final absent = attendance.where((a) => !a.present).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttendanceStat(label: 'حاضر', value: present, color: Colors.green),
              _AttendanceStat(label: 'غایب', value: absent, color: Colors.red),
              _AttendanceStat(label: 'کل', value: attendance.length, color: Colors.blue),
            ],
          ),
        ),
        Expanded(
          child: attendance.isEmpty
              ? const Center(child: Text('داده‌ای موجود نیست', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: attendance.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (ctx, i) {
                    final a = attendance[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          a.present ? Icons.check_circle : Icons.cancel,
                          color: a.present ? Colors.green : Colors.red,
                        ),
                        title: Text('جلسه #${a.sessionId}'),
                        subtitle: Text(a.present ? 'حاضر' : 'غایب'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          JalaliHelper.toPersianDigits(value.toString()),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
