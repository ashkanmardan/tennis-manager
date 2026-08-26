import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/training_package.dart';
import '../../../data/models/player.dart';
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
        title: const Text('وضعیت مالی', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<_FinanceData>(
        future: _loadData(repo),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = snap.data!;
          if (data.pkg == null) {
            return const _NoPkgState();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _SmartSummaryCard(data: data),
              const SizedBox(height: 14),
              _MonthlyCard(data: data),
              const SizedBox(height: 14),
              if (data.payments.isNotEmpty) ...[
                const _SectionHeader('تاریخچه پرداخت‌ها'),
                const SizedBox(height: 8),
                for (final p in data.payments)
                  _PaymentTile(payment: p,
                      onDelete: () => _confirmDelete(ctx, repo, p)),
              ] else
                const _EmptyPayments(),
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
    final Player? player = repo.player;
    return _FinanceData(pkg: pkg, payments: payments, player: player);
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
  final TrainingPackage? pkg;
  final List<Payment> payments;
  final Player? player;

  _FinanceData({required this.pkg, required this.payments, this.player});

  int get totalPrice => pkg?.price ?? 0;
  int get paidAmount => pkg?.paidAmount ?? 0;
  int get debt => (totalPrice - paidAmount).clamp(0, totalPrice);
  int get overpaid => paidAmount > totalPrice ? paidAmount - totalPrice : 0;
  bool get isSettled => paidAmount >= totalPrice;

  int get participants => player?.classParticipants ?? 1;

  /// تعداد روزهای تمرین در هفته
  int get sessionsPerWeek {
    final td = player?.trainingDays ?? '';
    if (td.isEmpty || td == '[]') return 2;
    if (td == 'odd') return 4;   // فرد: ش د س چ پ = ۵ روز → معمولاً ۳ روز
    if (td == 'even') return 3;  // زوج: ی س پ = ۳ روز
    // آرایه JSON از روزهای خاص
    try {
      final list = player?.trainingDaysList ?? [];
      return list.length.clamp(1, 7);
    } catch (_) { return 2; }
  }

  /// تعداد جلسات در ماه (۴ هفته × روزهای هفته)
  int get sessionsPerMonth => sessionsPerWeek * 4;

  /// هزینه هر جلسه = قیمت کل ÷ تعداد کل جلسات
  int get pricePerSession {
    final total = pkg?.totalSessions ?? 0;
    if (total == 0 || totalPrice == 0) return 0;
    return totalPrice ~/ total;
  }

  /// هزینه ماهانه = هزینه هر جلسه × جلسات ماهانه
  int get monthlyDue => pricePerSession * sessionsPerMonth;

  /// اضافه‌پرداخت یا کسری نسبت به تعداد جلسات برگزارشده
  int get smartBalance {
    final completed = pkg?.completedSessions ?? 0;
    final shouldHavePaid = pricePerSession * completed;
    return paidAmount - shouldHavePaid; // مثبت = طلبکار، منفی = بدهکار
  }
}

// ── Smart Summary Card ─────────────────────────────────────────────────────────
class _SmartSummaryCard extends StatelessWidget {
  final _FinanceData data;
  const _SmartSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final pkg = data.pkg!;
    final isOver = data.overpaid > 0;
    final isSettled = data.isSettled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver
              ? [const Color(0xFF0A6E5A), AppColors.accent]
              : data.debt > 0
                  ? [AppColors.debt, const Color(0xFFE53935)]
                  : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: (isOver ? AppColors.accent : data.debt > 0
                ? AppColors.debt : AppColors.primary).withAlpha(60),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // عنوان پکیج
        Row(children: [
          const Icon(Icons.class_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(pkg.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          if (data.participants > 1) ...[
            const Icon(Icons.group_outlined, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text('${data.participants} نفر',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ]),
        const SizedBox(height: 14),

        // ردیف اعداد اصلی
        Row(children: [
          _SummaryItem(label: 'کل دوره',
              value: JalaliHelper.formatAmount(data.totalPrice), suffix: 'تومان'),
          const SizedBox(width: 16),
          _SummaryItem(label: 'پرداخت شده',
              value: JalaliHelper.formatAmount(data.paidAmount), suffix: 'تومان'),
          const SizedBox(width: 16),
          if (isOver)
            _SummaryItem(label: 'طلبکاری', emoji: '🎉',
                value: JalaliHelper.formatAmount(data.overpaid), suffix: 'تومان')
          else if (isSettled)
            _SummaryItem(label: 'وضعیت', value: '✅', suffix: 'تسویه')
          else
            _SummaryItem(label: 'بدهی',
                value: JalaliHelper.formatAmount(data.debt), suffix: 'تومان'),
        ]),
        const SizedBox(height: 14),

        // بار پیشرفت
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: data.totalPrice == 0 ? 0
                : (data.paidAmount / data.totalPrice).clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            color: isOver ? AppColors.neonGreen : isSettled ? AppColors.neonGreen : Colors.white,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 10),

        // پیام هوشمند
        _SmartMessage(data: data),
      ]),
    );
  }
}

class _SmartMessage extends StatelessWidget {
  final _FinanceData data;
  const _SmartMessage({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.overpaid > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${JalaliHelper.formatAmount(data.overpaid)} تومان بیشتر واریز کردی و از استادت طلبکار شدی!',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          )),
        ]),
      );
    } else if (data.isSettled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Text('✅', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('حساب با استادت تسویه‌ست 👏',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${JalaliHelper.formatAmount(data.debt)} تومان بدهکاری — پرداخت رو فراموش نکن',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          )),
        ]),
      );
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value, suffix;
  final String? emoji;
  const _SummaryItem({required this.label, required this.value, required this.suffix,
      this.emoji});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    const SizedBox(height: 2),
    Row(children: [
      if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 4)],
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 17,
          fontWeight: FontWeight.bold)),
    ]),
    Text(suffix, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

// ── Monthly Card ───────────────────────────────────────────────────────────────
class _MonthlyCard extends StatelessWidget {
  final _FinanceData data;
  const _MonthlyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final monthly = data.monthlyDue;
    final perSession = data.pricePerSession;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: AppColors.primary, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calculate_outlined, color: AppColors.primary, size: 16),
          SizedBox(width: 6),
          Text('محاسبه ماهانه', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
              color: AppColors.primaryDark)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CalcItem(
            icon: Icons.payments_outlined,
            label: 'هر جلسه',
            value: JalaliHelper.formatAmount(perSession),
            suffix: 'تومان',
            color: AppColors.primary,
          )),
          Expanded(child: _CalcItem(
            icon: Icons.calendar_month_outlined,
            label: 'ماهانه تقریبی',
            value: JalaliHelper.formatAmount(monthly),
            suffix: 'تومان',
            color: AppColors.accent,
          )),
          if (data.participants > 1)
            Expanded(child: _CalcItem(
              icon: Icons.group_outlined,
              label: 'نفرات کلاس',
              value: JalaliHelper.toPersianDigits(data.participants.toString()),
              suffix: 'نفر',
              color: AppColors.makeup,
            )),
        ]),
        if (data.sessionsPerMonth > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'بر اساس ${JalaliHelper.toPersianDigits(data.sessionsPerWeek.toString())} جلسه در هفته · '
                '${JalaliHelper.toPersianDigits(data.sessionsPerMonth.toString())} جلسه در ماه · '
                '${JalaliHelper.toPersianDigits(data.pricePerSession.toString())} تومان هر جلسه',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              )),
            ]),
          ),
          const SizedBox(height: 8),
          // وضعیت نسبت به جلسات برگزارشده
          _SmartBalanceRow(data: data),
        ],
      ]),
    );
  }
}


class _SmartBalanceRow extends StatelessWidget {
  final _FinanceData data;
  const _SmartBalanceRow({required this.data});
  @override
  Widget build(BuildContext context) {
    final balance = data.smartBalance;
    final completed = data.pkg?.completedSessions ?? 0;
    if (completed == 0) return const SizedBox.shrink();
    final isOver = balance > 0;
    final isExact = balance == 0;
    final color = isOver ? AppColors.accent : isExact ? Colors.grey : AppColors.debt;
    final emoji = isOver ? '🎉' : isExact ? '✅' : '⚠️';
    final msg = isOver
        ? '${JalaliHelper.formatAmount(balance)} تومان بیشتر پرداختی (طلبکار)'
        : isExact
            ? 'دقیقاً برابر با جلسات برگزارشده پرداختی'
            : '${JalaliHelper.formatAmount(-balance)} تومان کمتر از جلسات برگزارشده پرداختی';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _CalcItem extends StatelessWidget {
  final IconData icon;
  final String label, value, suffix;
  final Color color;
  const _CalcItem({required this.icon, required this.label,
      required this.value, required this.suffix, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: color),
    ),
    const SizedBox(height: 6),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    Text(suffix, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ]);
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
          color: AppColors.primaryDark));
}

// ── Payment Tile ───────────────────────────────────────────────────────────────
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
      dateLabel = '${JalaliHelper.toPersianDigits(j.day.toString())} '
          '${JalaliHelper.monthName(j.month)} '
          '${JalaliHelper.toPersianDigits(j.year.toString())}';
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: AppColors.accent, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6),
            blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10)),
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

// ── Empty States ───────────────────────────────────────────────────────────────
class _NoPkgState extends StatelessWidget {
  const _NoPkgState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('💰', style: TextStyle(fontSize: 56)),
      const SizedBox(height: 16),
      const Text('هنوز کلاسی ثبت نشده', style: TextStyle(color: Colors.grey, fontSize: 15)),
      const SizedBox(height: 8),
      const Text('ابتدا از بخش «زمان کلاس شما» کلاس بسازید',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.account_balance_wallet_outlined, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('هنوز پرداختی ثبت نشده', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    ),
  );
}

// ── Add Payment Sheet ──────────────────────────────────────────────────────────
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
    decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
