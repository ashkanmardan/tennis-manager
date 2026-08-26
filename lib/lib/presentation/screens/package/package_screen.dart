import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/training_package.dart';
import '../../../data/repositories/app_repository.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('پکیج تمرینی', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<TrainingPackage>>(
        future: repo.packageRepo.getAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final packages = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: packages.isEmpty
                ? [const _EmptyState()]
                : [for (final pkg in packages) _PackageCard(pkg: pkg)],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('پکیج جدید', style: TextStyle(color: Colors.white)),
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddPackageSheet(repo: repo)),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TrainingPackage pkg;
  const _PackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final fraction = pkg.progressFraction.clamp(0.0, 1.0);
    final debt = pkg.debt;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: pkg.isActive
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header strip
        if (pkg.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(pkg.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('فعال',
                    style: TextStyle(color: AppColors.primaryDark, fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(pkg.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              RichText(text: TextSpan(children: [
                TextSpan(
                    text: JalaliHelper.toPersianDigits(pkg.completedSessions.toString()),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark)),
                TextSpan(
                    text: ' / ${JalaliHelper.toPersianDigits(pkg.totalSessions.toString())}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ])),
              const Spacer(),
              Text('${JalaliHelper.toPersianDigits(pkg.remainingSessions.toString())} جلسه مانده',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppColors.primary.withAlpha(20),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(children: [
              _InfoItem(label: 'مبلغ کل',
                  value: JalaliHelper.formatAmount(pkg.price), suffix: 'تومان'),
              const SizedBox(width: 20),
              _InfoItem(label: 'پرداخت شده',
                  value: JalaliHelper.formatAmount(pkg.paidAmount), suffix: 'تومان',
                  valueColor: AppColors.accent),
              const SizedBox(width: 20),
              _InfoItem(label: 'مانده',
                  value: debt == 0 ? 'تسویه' : JalaliHelper.formatAmount(debt),
                  suffix: debt == 0 ? '✅' : 'تومان',
                  valueColor: debt > 0 ? AppColors.debt : AppColors.accent),
            ]),
            if (pkg.startDate.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text('شروع: ${_fmtDate(pkg.startDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  String _fmtDate(String iso) {
    try {
      final p = iso.split('-');
      if (p.length == 3) {
        return '${JalaliHelper.toPersianDigits(p[2])} '
            '${JalaliHelper.monthName(int.parse(p[1]))} '
            '${JalaliHelper.toPersianDigits(p[0])}';
      }
    } catch (_) {}
    return iso;
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value, suffix;
  final Color? valueColor;
  const _InfoItem({required this.label, required this.value, required this.suffix, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
        color: valueColor ?? Colors.black87)),
    Text(suffix, style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('هنوز پکیجی ثبت نشده', style: TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('با دکمه زیر پکیج اول را اضافه کنید',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    ),
  );
}

class _AddPackageSheet extends StatefulWidget {
  final AppRepository repo;
  const _AddPackageSheet({required this.repo});
  @override
  State<_AddPackageSheet> createState() => _AddPackageSheetState();
}

class _AddPackageSheetState extends State<_AddPackageSheet> {
  final _nameCtrl  = TextEditingController(text: 'پکیج تمرینی');
  final _countCtrl = TextEditingController(text: '12');
  final _priceCtrl = TextEditingController();
  late String _startDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final j = JalaliHelper.today;
    _startDate = '${j.year}-${j.month.toString().padLeft(2,'0')}-${j.day.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() { _nameCtrl.dispose(); _countCtrl.dispose(); _priceCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final totalSessions = int.tryParse(_countCtrl.text.trim()) ?? 0;
    final price = int.tryParse(_priceCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (totalSessions <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.repo.addPackage(TrainingPackage(
        name: _nameCtrl.text.trim().isEmpty ? 'پکیج تمرینی' : _nameCtrl.text.trim(),
        totalSessions: totalSessions,
        price: price,
        startDate: _startDate,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        completedSessions: 0,
        paidAmount: 0,
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
        const Text('پکیج جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _field(_nameCtrl, 'نام پکیج', Icons.label_outline),
        const SizedBox(height: 12),
        _field(_countCtrl, 'تعداد جلسات', Icons.sports_tennis, inputType: TextInputType.number),
        const SizedBox(height: 12),
        _field(_priceCtrl, 'مبلغ (تومان)', Icons.payments_outlined, inputType: TextInputType.number),
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
                : const Text('ذخیره پکیج', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? inputType}) =>
      TextField(
        controller: ctrl, keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          filled: true, fillColor: const Color(0xFFF5F5F5),
        ),
      );
}
