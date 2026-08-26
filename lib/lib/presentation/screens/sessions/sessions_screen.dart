import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../core/utils/iranian_holidays.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/app_repository.dart';
import 'add_session_sheet.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late int _year, _month;

  @override
  void initState() {
    super.initState();
    final j = JalaliHelper.today;
    _year = j.year; _month = j.month;
  }

  void _prevMonth() => setState(() {
    if (_month == 1) { _month = 12; _year--; } else _month--;
  });
  void _nextMonth() => setState(() {
    if (_month == 12) { _month = 1; _year++; } else _month++;
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('جلسات', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthBar(year: _year, month: _month,
              onPrev: _prevMonth, onNext: _nextMonth),
        ),
      ),
      body: _SessionList(year: _year, month: _month),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddSessionSheet(repo: repo)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('جلسه جدید', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final int year, month;
  final VoidCallback onPrev, onNext;
  const _MonthBar({required this.year, required this.month,
      required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primaryDark,
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: onNext),
      Expanded(
        child: Text(
          '${JalaliHelper.monthName(month)} ${JalaliHelper.toPersianDigits(year.toString())}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: onPrev),
    ]),
  );
}

class _SessionList extends StatelessWidget {
  final int year, month;
  const _SessionList({required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    return FutureBuilder<List<Session>>(
      future: repo.sessionRepo.getByMonth(year, month),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final sessions = snap.data!;
        if (sessions.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sports_tennis, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('این ماه جلسه‌ای ندارید', style: TextStyle(color: Colors.grey)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: sessions.length,
          itemBuilder: (_, i) => _SessionTile(
            session: sessions[i],
            onTap: () => Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => SessionDetailScreen(
                  sessionId: sessions[i].id!, repo: repo))),
          ),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  const _SessionTile({required this.session, required this.onTap});

  Color _statusColor(SessionStatus s) {
    switch (s) {
      case SessionStatus.completed:          return AppColors.accent;
      case SessionStatus.upcoming:           return AppColors.primary;
      case SessionStatus.cancelledByCoach:
      case SessionStatus.cancelledByPlayer:  return AppColors.debt;
      case SessionStatus.weather:            return Colors.indigo;
      case SessionStatus.holiday:            return const Color(0xFFE91E8C);
      case SessionStatus.rescheduled:        return AppColors.makeup;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session.scheduledDate);
    final jalali = date != null ? JalaliHelper.toJalali(date) : null;
    final weekDay = date != null
        ? JalaliHelper.weekDays[(date.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} ${JalaliHelper.monthName(jalali.month)}'
        : session.scheduledDate;

    // جلسه گذشته که نتیجه‌اش ثبت نشده
    final isOverdue = session.status == SessionStatus.upcoming &&
        date != null && date.isBefore(DateTime.now());

    // وضعیت واقعی برای رنگ‌بندی
    final displayStatus = isOverdue ? SessionStatus.cancelledByCoach : session.status;
    final color = _statusColor(displayStatus);

    // تعطیل رسمی
    final isHoliday = jalali != null &&
        IranianHolidays.isHoliday(session.scheduledDate, jalali.month, jalali.day);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHoliday ? const Color(0xFFFCE4EC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(
            color: isHoliday ? const Color(0xFFE91E8C) : color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(session.status.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (session.isMakeup) ...[
                  const SizedBox(width: 8),
                  _SmallBadge('جبرانی', AppColors.makeup),
                ],
                if (isHoliday) ...[
                  const SizedBox(width: 8),
                  _SmallBadge('تعطیل', const Color(0xFFE91E8C)),
                ],
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  _SmallBadge('بدون نتیجه', Colors.orange.shade700),
                ],
              ]),
              const SizedBox(height: 3),
              Text(isOverdue ? 'نتیجه ثبت نشده' : session.status.label,
                  style: TextStyle(fontSize: 12, color: color)),
            ])),
            if (session.time != null)
              Text(session.time!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _SmallBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, color: color)),
  );
}
