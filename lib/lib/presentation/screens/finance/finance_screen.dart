import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/training_package.dart';
import '../../../data/repositories/app_repository.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('مالی', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<_FinanceData>(
        future: _loadData(repo),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (data.activePackage != null) _SummaryCard(pkg: data.activePackage!),
              const SizedBox(height: 16),
              if (data.payments.isEmpty)
                const _EmptyState()
              else ...[
                const Text('تاریخچه پرداخت‌ها',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 10),
                for (final p in data.payments)
                  _PaymentTile(payment: p,
                      onDelete: () => _confirmDelete(ctx, repo, p)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ثبت پرداخت', style: TextStyle(color: Colors.white)),
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddPaymentSheet(repo: repo)),
      ),
    );
  }

  Future<_FinanceData> _loadData(AppRepository repo) async {
    final pkg = repo.activePackage;
    final payments = pkg != null
        ? await repo.financeRepo.getByPackage(pkg.id!)
        : await repo.financeRepo.getAll();
    return _FinanceData(activePackage: pkg, payments: payments);
  }

  Future<void> _confirmDelete(BuildContext context, AppRepository repo, Payment payment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف پرداخت'),
        content: Text('پرداخت ${JalaliHelper.formatAmount(payment.amount)} تومان حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('خیر')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.financeRepo.delete(payment.id!);
      await repo.loadAll();
    }
  }
}

class _FinanceData {
  final TrainingPackage? activePackage;
  final List<Payment> payments;
  const _FinanceData({required this.activePackage, required this.payments});
}

class _SummaryCard extends StatelessWidget {
  final TrainingPackage pkg;
  const _SummaryCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final debt = pkg.debt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: debt > 0
              ? [AppColors.debt, const Color(0xFFE53935)]
              : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: (debt > 0 ? AppColors.debt : AppColors.primary).withAlpha(60),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(pkg.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _SummaryItem(label: 'کل پکیج',
              value: JalaliHelper.formatAmount(pkg.price), suffix: 'تومان'),
          const SizedBox(width: 20),
          _SummaryItem(label: 'پرداخت شده',
              value: JalaliHelper.formatAmount(pkg.paidAmount), suffix: 'تومان'),
          const SizedBox(width: 20),
          _SummaryItem(
              label: debt > 0 ? 'بدهی' : 'وضعیت',
              value: debt > 0 ? JalaliHelper.formatAmount(debt) : '✅',
              suffix: debt > 0 ? 'تومان' : 'تسویه'),
        ]),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value, suffix;
  const _SummaryItem({required this.label, required this.value, required this.suffix});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(suffix, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onDelete;
  const _PaymentTile({required this.payment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    String dateLabel = payment.paymentDate;
    try {
      final d = DateTime.parse(payment.paymentDate);
      final j = JalaliHelper.toJalali(d);
      dateLabel = '${JalaliHelper.toPersianDigits(j.day.toString())} ${JalaliHelper.monthName(j.month)}';
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: AppColors.accent, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text('💵', style: TextStyle(fontSize: 20)),
        ),
        title: Text('${JalaliHelper.formatAmount(payment.amount)} تومان',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dateLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('هنوز پرداختی ثبت نشده', style: TextStyle(color: Colors.grey, fontSize: 15)),
      ]),
    ),
  );
}

class _AddPaymentSheet extends StatefulWidget {
  final AppRepository repo;
  const _AddPaymentSheet({required this.repo});
  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  late String _paymentDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() { _amountCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final amount = int.tryParse(_amountCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final pkg = widget.repo.activePackage;
      await widget.repo.addPayment(Payment(
        amount: amount,
        paymentDate: _paymentDate,
        packageId: pkg?.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8, left: 16, right: 16),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const Text('ثبت پرداخت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _amountCtrl, keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'مبلغ (تومان)',
            prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary)),
            filled: true, fillColor: const Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesCtrl,
          decoration: InputDecoration(
            labelText: 'یادداشت (اختیاری)',
            prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary)),
            filled: true, fillColor: const Color(0xFFF5F5F5),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ذخیره پرداخت', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    ),
  );
}
