import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/app_repository.dart';

class SessionDetailScreen extends StatefulWidget {
  final int sessionId;
  final AppRepository repo;
  const SessionDetailScreen({super.key, required this.sessionId, required this.repo});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    final all = await widget.repo.sessionRepo.getAll();
    final s = all.where((s) => s.id == widget.sessionId).cast<Session?>().firstOrNull;
    if (mounted) setState(() { _session = s; _loading = false; });
  }

  Future<void> _setStatus(SessionStatus status) async {
    if (_session?.id == null) return;
    setState(() => _saving = true);
    await widget.repo.updateSessionStatus(_session!.id!, status);
    await _loadSession();            // بارگذاری مجدد — بدون بستن صفحه
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جلسه'),
        content: const Text('این جلسه حذف شود؟'),
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
    if (ok == true && _session?.id != null) {
      await widget.repo.sessionRepo.delete(_session!.id!);
      await widget.repo.loadAll();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_session == null) {
      return const Scaffold(body: Center(child: Text('جلسه یافت نشد')));
    }

    final session = _session!;
    final date = DateTime.tryParse(session.scheduledDate);
    final jalali = date != null ? JalaliHelper.toJalali(date) : null;
    final weekDay = date != null ? JalaliHelper.weekDays[(date.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} '
          '${JalaliHelper.monthName(jalali.month)} '
          '${JalaliHelper.toPersianDigits(jalali.year.toString())}'
        : session.scheduledDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text(dateLabel, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // کارت وضعیت فعلی
          _Card(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(session.status.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(session.status.label,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark)),
            if (session.isMakeup) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.makeup.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('جلسه جبرانی',
                    style: TextStyle(color: AppColors.makeup, fontWeight: FontWeight.w500)),
              ),
            ],
          ])),
          const SizedBox(height: 14),
          // کارت اطلاعات
          _Card(child: Column(children: [
            _row(Icons.calendar_today_outlined, 'تاریخ', dateLabel),
            if (session.time != null)
              _row(Icons.access_time_outlined, 'ساعت', session.time!),
            _row(Icons.timer_outlined, 'مدت',
                '${JalaliHelper.toPersianDigits(session.duration.toString())} دقیقه'),
          ])),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Card(child: _row(Icons.notes_outlined, 'یادداشت', session.notes!)),
          ],
          // همیشه نمایش بده — قابل ویرایش در هر زمان
          const SizedBox(height: 20),
          _updateStatusSection(),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _updateStatusSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('ثبت / ویرایش نتیجه جلسه',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
              color: AppColors.primaryDark)),
      const SizedBox(height: 12),
      if (_saving)
        const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ))
      else ...[
        _statusBtn(SessionStatus.completed, 'برگزار شد', AppColors.accent),
        const SizedBox(height: 8),
        _statusBtn(SessionStatus.cancelledByCoach,
            'لغو توسط مربی  •  جلسه جبرانی ایجاد می‌شود', AppColors.debt),
        const SizedBox(height: 8),
        _statusBtn(SessionStatus.cancelledByPlayer, 'لغو توسط من', AppColors.makeup),
        const SizedBox(height: 8),
        _statusBtn(SessionStatus.weather,
            'لغو آب‌وهوایی  •  جلسه جبرانی ایجاد می‌شود', Colors.indigo),
        const SizedBox(height: 8),
        _statusBtn(SessionStatus.holiday, 'تعطیل رسمی', const Color(0xFFE91E8C)),
        const SizedBox(height: 8),
        _statusBtn(SessionStatus.rescheduled, 'تغییر زمان', Colors.blueGrey),
      ],
    ],
  );

  Widget _statusBtn(SessionStatus s, String label, Color color) {
    final isSelected = _session?.status == s;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _setStatus(s),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(children: [
              Text(s.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : color.withAlpha(200)))),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}
