import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/app_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _year;
  late int _month;
  Map<String, dynamic>? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final j = JalaliHelper.today;
    _year = j.year;
    _month = j.month;
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final repo = context.read<AppRepository>();
    final data = await repo.getMonthlyReport(_year, _month);
    if (mounted) setState(() { _report = data; _loading = false; });
  }

  void _changeMonth(bool next) {
    setState(() {
      if (next) {
        if (_month == 12) { _month = 1; _year++; } else _month++;
      } else {
        if (_month == 1) { _month = 12; _year--; } else _month--;
      }
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('گزارش‌ها')),
      body: Column(
        children: [
          // Month selector
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () => _changeMonth(false),
                ),
                Expanded(
                  child: Text(
                    '${JalaliHelper.monthName(_month)} ${JalaliHelper.toPersianDigits(_year.toString())}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _changeMonth(true),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _report == null
                    ? const Center(child: Text('خطا در بارگذاری گزارش'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Sessions section
                          _SectionHeader(title: 'جلسات', icon: Icons.sports_tennis),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ReportCard(
                                  label: 'کل جلسات',
                                  value: JalaliHelper.toPersianDigits(
                                      _report!['session_count'].toString()),
                                  color: Colors.blue,
                                  icon: Icons.calendar_month,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReportCard(
                                  label: 'عادی',
                                  value: JalaliHelper.toPersianDigits(
                                      _report!['regular_sessions'].toString()),
                                  color: Colors.green,
                                  icon: Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ReportCard(
                                  label: 'جبرانی',
                                  value: JalaliHelper.toPersianDigits(
                                      _report!['makeup_sessions'].toString()),
                                  color: Colors.orange,
                                  icon: Icons.repeat,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReportCard(
                                  label: 'لغو‌شده',
                                  value: JalaliHelper.toPersianDigits(
                                      _report!['cancelled_sessions'].toString()),
                                  color: Colors.red,
                                  icon: Icons.cancel,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Financial section
                          _SectionHeader(title: 'مالی', icon: Icons.monetization_on),
                          const SizedBox(height: 8),
                          _FinancialRow(
                            label: 'کل درآمد دریافتی',
                            amount: _report!['total_income'],
                            color: Colors.green,
                          ),
                          _FinancialRow(
                            label: 'هزینه توپ',
                            amount: _report!['total_ball_costs'],
                            color: Colors.orange,
                          ),
                          _FinancialRow(
                            label: 'سود خالص',
                            amount: (_report!['total_income'] - _report!['total_ball_costs'])
                                .clamp(0, double.maxFinite)
                                .toInt(),
                            color: Colors.blue,
                          ),

                          const SizedBox(height: 20),

                          // Students section
                          _SectionHeader(title: 'شاگردان', icon: Icons.people),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ReportCard(
                                  label: 'شاگرد فعال',
                                  value: JalaliHelper.toPersianDigits(
                                      repo.activeStudents.length.toString()),
                                  color: Colors.blue,
                                  icon: Icons.people,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ReportCard(
                                  label: 'تعداد پرداخت',
                                  value: JalaliHelper.toPersianDigits(
                                      _report!['payment_count'].toString()),
                                  color: Colors.green,
                                  icon: Icons.receipt,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Student debt list
                          _SectionHeader(title: 'وضعیت بدهی شاگردان', icon: Icons.warning_amber),
                          const SizedBox(height: 8),
                          ...repo.activeStudents.map((student) => _StudentDebtTile(
                                student: student,
                              )),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ReportCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _FinancialRow({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${JalaliHelper.formatAmount(amount)} تومان',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _StudentDebtTile extends StatefulWidget {
  final Student student;

  const _StudentDebtTile({required this.student});

  @override
  State<_StudentDebtTile> createState() => _StudentDebtTileState();
}

class _StudentDebtTileState extends State<_StudentDebtTile> {
  int _debt = 0;

  @override
  void initState() {
    super.initState();
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    final debt = await context.read<AppRepository>().getStudentDebt(widget.student);
    if (mounted) setState(() => _debt = debt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _debt > 0 ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            _debt > 0 ? Icons.warning_amber : Icons.check,
            size: 16,
            color: _debt > 0 ? Colors.red : Colors.green,
          ),
        ),
        title: Text(widget.student.name, style: const TextStyle(fontSize: 14)),
        trailing: Text(
          _debt > 0 ? '${JalaliHelper.formatAmount(_debt)} ت بدهکار' : 'تسویه',
          style: TextStyle(
            color: _debt > 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
