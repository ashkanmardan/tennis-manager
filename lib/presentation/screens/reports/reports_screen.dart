import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/models/session.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('آمار و گزارش', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<_ReportData>(
        future: _loadData(repo),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _SummaryCard(data: d),
              const SizedBox(height: 16),
              _MonthlyGrid(data: d),
              const SizedBox(height: 16),
              _StatusBreakdown(data: d),
            ],
          );
        },
      ),
    );
  }

  Future<_ReportData> _loadData(AppRepository repo) async {
    final all = await repo.sessionRepo.getAll();
    return _ReportData(sessions: all, pkg: repo.activePackage);
  }
}

class _ReportData {
  final List<Session> sessions;
  final dynamic pkg;

  _ReportData({required this.sessions, this.pkg});

  int get total => sessions.length;
  int get completed => sessions.where((s) => s.status == SessionStatus.completed).length;
  int get cancelledByCoach => sessions.where((s) => s.status == SessionStatus.cancelledByCoach).length;
  int get cancelledByPlayer => sessions.where((s) => s.status == SessionStatus.cancelledByPlayer).length;
  int get weatherCount => sessions.where((s) => s.status == SessionStatus.weather).length;
  int get makeup => sessions.where((s) => s.isMakeup).length;
  double get attendanceRate => total == 0 ? 0 : completed / total;

  // ماه جاری
  Map<String, int> get currentMonthCounts {
    final j = JalaliHelper.today;
    final thisMonth = sessions.where((s) =>
        s.jalaliYear == j.year && s.jalaliMonth == j.month).toList();
    return {
      'completed': thisMonth.where((s) => s.status == SessionStatus.completed).length,
      'cancelled': thisMonth.where((s) =>
          s.status != SessionStatus.upcoming && s.status != SessionStatus.completed).length,
      'upcoming': thisMonth.where((s) => s.status == SessionStatus.upcoming).length,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final _ReportData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = (data.attendanceRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60),
            blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatBubble(
              value: JalaliHelper.toPersianDigits(data.completed.toString()),
              label: 'برگزار شده', color: AppColors.neonGreen),
          _StatBubble(
              value: '${JalaliHelper.toPersianDigits(pct.toString())}٪',
              label: 'حضور', color: Colors.white),
          _StatBubble(
              value: JalaliHelper.toPersianDigits(data.total.toString()),
              label: 'کل جلسات', color: Colors.white70),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: data.attendanceRate,
            backgroundColor: Colors.white24,
            color: AppColors.neonGreen,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text('نرخ حضور شما: ${JalaliHelper.toPersianDigits(pct.toString())}٪',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBubble({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);
}

class _MonthlyGrid extends StatelessWidget {
  final _ReportData data;
  const _MonthlyGrid({required this.data});
  @override
  Widget build(BuildContext context) {
    final j = JalaliHelper.today;
    final counts = data.currentMonthCounts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ماه جاری — ${JalaliHelper.monthName(j.month)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
              color: AppColors.primaryDark)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _MiniStat('برگزار شده', counts['completed']!, AppColors.accent, '✅')),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat('لغو شده', counts['cancelled']!, Colors.red.shade400, '❌')),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat('پیش‌رو', counts['upcoming']!, AppColors.primary, '📅')),
      ]),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String emoji;
  const _MiniStat(this.label, this.count, this.color, this.emoji);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withAlpha(50)),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 6),
      Text(JalaliHelper.toPersianDigits(count.toString()),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center),
    ]),
  );
}

class _StatusBreakdown extends StatelessWidget {
  final _ReportData data;
  const _StatusBreakdown({required this.data});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('تفکیک وضعیت‌ها', style: TextStyle(fontWeight: FontWeight.bold,
        fontSize: 15, color: AppColors.primaryDark)),
    const SizedBox(height: 10),
    _StatusRow('برگزار شده', data.completed, AppColors.accent, data.total),
    _StatusRow('لغو توسط مربی', data.cancelledByCoach, AppColors.makeup, data.total),
    _StatusRow('لغو توسط من', data.cancelledByPlayer, AppColors.debt, data.total),
    _StatusRow('آب‌وهوا', data.weatherCount, Colors.indigo, data.total),
    _StatusRow('جلسات جبرانی', data.makeup, AppColors.makeup, data.total),
  ]);
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;
  const _StatusRow(this.label, this.count, this.color, this.total);
  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : count / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(JalaliHelper.toPersianDigits(count.toString()),
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            backgroundColor: color.withAlpha(20),
            color: color,
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}
