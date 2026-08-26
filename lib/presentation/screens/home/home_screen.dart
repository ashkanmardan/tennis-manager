import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../core/utils/iranian_holidays.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/app_repository.dart';
import '../sessions/session_detail_screen.dart';
import '../../widgets/app_drawer.dart';
import '../sessions/sessions_screen.dart';
import '../finance/finance_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    if (repo.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final playerName = repo.player?.name ?? 'بازیکن';
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => repo.loadAll(),
        child: CustomScrollView(
          slivers: [
            _TealAppBar(playerName: playerName, nextSession: repo.nextSession),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _QuickNavRow(),
                  const SizedBox(height: 10),
                  _MainSessionCard(session: repo.nextSession, repo: repo),
                  if (repo.unresolvedPastSession != null) ...[
                    const SizedBox(height: 10),
                    _UnresolvedPastCard(
                        session: repo.unresolvedPastSession!, repo: repo),
                  ],
                  const SizedBox(height: 10),
                  _CoachDebtCard(count: repo.coachDebtCount, repo: repo),
                  const SizedBox(height: 10),
                  _FinanceCard(pkg: repo.activePackage),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar با تایمر متحرک ────────────────────────────────────────────────────
class _TealAppBar extends StatelessWidget {
  final String playerName;
  final Session? nextSession;
  const _TealAppBar({required this.playerName, this.nextSession});

  @override
  Widget build(BuildContext context) {
    final jalali = JalaliHelper.today;
    final weekDay = JalaliHelper.weekDays[(jalali.weekDay - 1) % 7];
    final dayNum = JalaliHelper.toPersianDigits(jalali.day.toString());
    final monthN = JalaliHelper.monthName(jalali.month);
    final dateStr = '$weekDay $dayNum $monthN';

    return SliverAppBar(
      backgroundColor: AppColors.primaryDark,
      expandedHeight: 148,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(60)),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          CustomPaint(painter: _CourtPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 60, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dateStr, style: const TextStyle(fontSize: 12,
                        color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(JalaliHelper.toPersianDigits(jalali.year.toString()),
                        style: const TextStyle(fontSize: 10, color: Colors.white38)),
                  ]),
                  Expanded(
                    child: Text('سلام $playerName! 👋',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 10),
                _TimerBar(nextSession: nextSession),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── تایمر متحرک در هدر ────────────────────────────────────────────────────────
class _TimerBar extends StatefulWidget {
  final Session? nextSession;
  const _TimerBar({this.nextSession});
  @override
  State<_TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<_TimerBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime? _getClassTime() {
    final s = widget.nextSession;
    if (s == null) return null;
    try {
      final dt = DateTime.parse(s.scheduledDate);
      final timeParts = (s.time ?? '17:00').split(':');
      return DateTime(dt.year, dt.month, dt.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classTime = _getClassTime();
    if (classTime == null) {
      return const SizedBox(height: 28);
    }

    final now = DateTime.now();
    final diff = classTime.difference(now);
    final totalHours = 12.0;
    final hoursLeft = diff.inMinutes / 60.0;

    double pct;
    if (hoursLeft <= 0) {
      pct = 1.0; // کلاس شروع شده
    } else if (hoursLeft >= totalHours) {
      pct = (totalHours - hoursLeft.clamp(0, totalHours)) / totalHours;
      pct = pct.clamp(0.0, 1.0);
    } else {
      pct = (totalHours - hoursLeft) / totalHours;
      pct = pct.clamp(0.0, 1.0);
    }

    // رنگ بر اساس زمان باقی‌مانده
    Color barColor;
    if (hoursLeft <= 0) {
      barColor = const Color(0xFFFF7043);
    } else if (hoursLeft < 0.5) {
      barColor = const Color(0xFFFFD54F);
    } else if (hoursLeft < 2) {
      barColor = AppColors.neonGreen;
    } else if (hoursLeft < 6) {
      barColor = const Color(0xFF81C784);
    } else {
      barColor = const Color(0xFF64B5F6);
    }

    String timerLabel;
    String timerValue;
    if (hoursLeft <= 0) {
      timerLabel = '🎾 کلاس شروع شده!';
      timerValue = 'همین الان';
    } else if (diff.inDays >= 1) {
      timerLabel = 'تا کلاس بعدی';
      timerValue = '${JalaliHelper.toPersianDigits(diff.inDays.toString())} روز';
    } else if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      timerLabel = 'تا کلاس بعدی';
      timerValue = m > 0
          ? '${JalaliHelper.toPersianDigits(h.toString())}:${JalaliHelper.toPersianDigits(m.toString().padLeft(2, '0'))} ساعت'
          : '${JalaliHelper.toPersianDigits(h.toString())} ساعت';
    } else {
      timerLabel = '⚡ الان کلاسته!';
      timerValue = '${JalaliHelper.toPersianDigits(diff.inMinutes.toString())} دقیقه';
    }

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(timerLabel,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
        Text(timerValue,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: barColor == AppColors.neonGreen ? AppColors.neonGreen : Colors.white)),
      ]),
      const SizedBox(height: 5),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: pct),
        duration: const Duration(milliseconds: 700),
        builder: (ctx, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(width: double.infinity, height: 5,
                color: Colors.white.withAlpha(35)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(height: 5, color: barColor),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('', style: TextStyle(fontSize: 8)),
        Text('${JalaliHelper.toPersianDigits((pct * 100).round().toString())}٪',
            style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(140))),
      ]),
    ]);
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTRB(12, 8, w - 12, h - 4), paint);
    canvas.drawLine(Offset(w / 2, 8), Offset(w / 2, h - 4), paint);
    final net = Paint()..color = Colors.white.withAlpha(45)..strokeWidth = 2;
    canvas.drawLine(Offset(12, h / 2), Offset(w - 12, h / 2), net);
    canvas.drawLine(Offset(w * 0.22, 8), Offset(w * 0.22, h / 2), paint);
    canvas.drawLine(Offset(w * 0.78, 8), Offset(w * 0.78, h / 2), paint);
    canvas.drawLine(Offset(w * 0.22, h / 2), Offset(w * 0.22, h - 4), paint);
    canvas.drawLine(Offset(w * 0.78, h / 2), Offset(w * 0.78, h - 4), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Quick Nav Row ─────────────────────────────────────────────────────────────
class _QuickNavRow extends StatelessWidget {
  const _QuickNavRow();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _NavCard(emoji: '🎾', label: 'جلسات', color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SessionsScreen()))),
      const SizedBox(width: 8),
      _NavCard(emoji: '💰', label: 'مالی', color: AppColors.accent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FinanceScreen()))),
      const SizedBox(width: 8),
      _NavCard(emoji: '📊', label: 'آمار', color: const Color(0xFF7B61FF),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()))),
      const SizedBox(width: 8),
      _NavCard(emoji: '🏅', label: 'مربی', color: AppColors.primaryDark,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()))),
    ]);
  }
}

class _NavCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _NavCard({required this.emoji, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: color)),
        ]),
      ),
    ),
  );
}

// ── کارت اصلی جلسه ────────────────────────────────────────────────────────────
// اگه امروز: دکمه‌ها نشون داده می‌شه
// اگه آینده: فقط اطلاعات (بدون دکمه)
class _MainSessionCard extends StatefulWidget {
  final Session? session;
  final AppRepository repo;
  const _MainSessionCard({required this.session, required this.repo});
  @override
  State<_MainSessionCard> createState() => _MainSessionCardState();
}

class _MainSessionCardState extends State<_MainSessionCard> {
  bool _busy = false;

  Future<void> _mark(SessionStatus status, {String? notes}) async {
    if (widget.session?.id == null) return;
    setState(() => _busy = true);
    await widget.repo.updateSessionStatus(widget.session!.id!, status, notes: notes);
    if (mounted) setState(() => _busy = false);
  }

  void _showCancel() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(onSelect: (s, n) => _mark(s, notes: n)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) return _noSession();
    final s = widget.session!;

    DateTime? dateTime;
    try { dateTime = DateTime.tryParse(s.scheduledDate); } catch (_) {}

    final jalali = dateTime != null ? _safeJalali(dateTime) : null;
    final weekDay = dateTime != null
        ? JalaliHelper.weekDays[(dateTime.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} ${JalaliHelper.monthName(jalali.month)}'
        : '---';

    final todayIso = DateTime.now().toIso8601String().substring(0, 10);
    final sessionIso = s.scheduledDate.substring(0, 10);
    final isToday = sessionIso == todayIso;

    final now = DateTime.now();
    final diff = dateTime != null ? dateTime.difference(now) : Duration.zero;

    final isHoliday = jalali != null &&
        IranianHolidays.isHoliday(s.scheduledDate, jalali.month, jalali.day);
    final accentColor = isHoliday ? const Color(0xFFE91E8C) : AppColors.primary;

    // دکمه‌ها فقط اگه امروز کلاس داریم نشون داده می‌شن
    final showButtons = isToday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: accentColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.event_note_outlined, color: accentColor, size: 13),
                const SizedBox(width: 4),
                Text(isToday ? 'کلاس امروز' : 'جلسه بعدی',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (s.isMakeup) ...[
                  const SizedBox(width: 6),
                  _Badge('جبرانی', AppColors.makeup),
                ],
                if (!isToday) ...[
                  const SizedBox(width: 6),
                  _Badge('آینده', AppColors.primary),
                ],
              ]),
              const SizedBox(height: 5),
              Text(dateLabel, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: isHoliday ? const Color(0xFFE91E8C) : AppColors.primaryDark)),
              if (s.time != null)
                Text('ساعت ${s.time} · ${s.duration} دقیقه',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withAlpha(50)),
              ),
              child: Text(isToday ? 'امروز' : _countdown(diff),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: accentColor)),
            ),
          ]),
        ),
        if (showButtons) ...[
          // کلاس امروزه — دکمه‌ها نشون داده می‌شن
          Container(height: 1, color: Colors.grey.shade100,
              margin: const EdgeInsets.symmetric(horizontal: 14)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(children: [
              const Text('آیا این کلاس برگزار می‌شه؟',
                  style: TextStyle(fontSize: 12, color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _busy
                  ? const SizedBox(height: 40, child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: AppColors.primary)))
                  : Row(children: [
                      Expanded(child: _QuestionBtn(
                        label: '✅  برگزار می‌شه',
                        selected: false,
                        selectedColor: AppColors.accent,
                        onTap: () => _mark(SessionStatus.completed),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _QuestionBtn(
                        label: '❌  لغو می‌شه',
                        selected: false,
                        selectedColor: Colors.red.shade400,
                        onTap: _showCancel,
                      )),
                    ]),
            ]),
          ),
        ] else ...[
          // جلسه آینده — فقط اطلاعات
          Container(height: 1, color: Colors.grey.shade100,
              margin: const EdgeInsets.symmetric(horizontal: 14)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(children: [
              Icon(Icons.schedule_outlined, size: 14,
                  color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text('در روز کلاس می‌تونی وضعیت رو ثبت کنی',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ),
        ],
      ]),
    );
  }

  String _countdown(Duration diff) {
    if (diff.isNegative || diff.inMinutes < 60) return 'امروز';
    final days = diff.inDays;
    if (days > 0) return '${JalaliHelper.toPersianDigits(days.toString())} روز';
    return '${JalaliHelper.toPersianDigits(diff.inHours.toString())} ساعت';
  }

  Widget _noSession() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: Colors.grey.shade300, width: 4))),
    child: Row(children: [
      Icon(Icons.calendar_today_outlined, color: Colors.grey.shade400, size: 28),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('جلسه‌ای برنامه‌ریزی نشده',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        Text('از تب جلسات اضافه کنید',
            style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    ]),
  );
}

// ── کارت جلسه ثبت‌نشده گذشته ─────────────────────────────────────────────────
// کوچک و فشرده — فقط یه جلسه گذشته رو می‌پرسه
class _UnresolvedPastCard extends StatefulWidget {
  final Session session;
  final AppRepository repo;
  const _UnresolvedPastCard({required this.session, required this.repo});
  @override
  State<_UnresolvedPastCard> createState() => _UnresolvedPastCardState();
}

class _UnresolvedPastCardState extends State<_UnresolvedPastCard> {
  bool _busy = false;

  Future<void> _mark(SessionStatus status, {String? notes}) async {
    setState(() => _busy = true);
    await widget.repo.updateSessionStatus(widget.session.id!, status, notes: notes);
    if (mounted) setState(() => _busy = false);
  }

  void _showCancel() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(onSelect: (s, n) => _mark(s, notes: n)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    DateTime? dt;
    try { dt = DateTime.tryParse(s.scheduledDate); } catch (_) {}
    final jalali = dt != null ? _safeJalali(dt) : null;
    final weekDay = dt != null ? JalaliHelper.weekDays[(dt.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} ${JalaliHelper.monthName(jalali.month)}'
        : '---';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text('جلسه $dateLabel ثبت نشده',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800)),
          ),
        ]),
        const SizedBox(height: 8),
        _busy
            ? SizedBox(height: 36, child: Center(
                child: CircularProgressIndicator(strokeWidth: 2,
                    color: Colors.orange.shade400)))
            : Row(children: [
                Expanded(child: _QuestionBtn(
                  label: '✅  برگزار شد',
                  selected: false,
                  selectedColor: AppColors.accent,
                  onTap: () => _mark(SessionStatus.completed),
                )),
                const SizedBox(width: 8),
                Expanded(child: _QuestionBtn(
                  label: '❌  لغو شد',
                  selected: false,
                  selectedColor: Colors.red.shade400,
                  onTap: _showCancel,
                )),
              ]),
      ]),
    );
  }
}

// ── دکمه سوال ─────────────────────────────────────────────────────────────────
class _QuestionBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  const _QuestionBtn({required this.label, required this.selected,
      required this.selectedColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? selectedColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? selectedColor : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade600)),
    ),
  );
}

// ── شیت لغو ───────────────────────────────────────────────────────────────────
class _CancelSheet extends StatelessWidget {
  final void Function(SessionStatus, String?) onSelect;
  const _CancelSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2))),
      const Text('علت لغو؟',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      _CancelOption(emoji: '❌', title: 'لغو توسط مربی',
          sub: 'جلسه جبرانی ثبت می‌شه',
          onTap: () { Navigator.pop(context);
              onSelect(SessionStatus.cancelledByCoach, null); }),
      _CancelOption(emoji: '🚫', title: 'لغو توسط من',
          sub: 'جلسه از دوره کسر می‌شه',
          onTap: () { Navigator.pop(context);
              onSelect(SessionStatus.cancelledByPlayer, null); }),
      _CancelOption(emoji: '🌧', title: 'آب‌وهوا / باران',
          sub: 'جلسه جبرانی ثبت می‌شه',
          onTap: () { Navigator.pop(context);
              onSelect(SessionStatus.weather, null); }),
      _CancelOption(emoji: '📅', title: 'تعطیل رسمی',
          sub: 'ثبت می‌شه بدون جبرانی',
          onTap: () { Navigator.pop(context);
              onSelect(SessionStatus.holiday, null); }),
    ]),
  );
}

class _CancelOption extends StatelessWidget {
  final String emoji, title, sub;
  final VoidCallback onTap;
  const _CancelOption({required this.emoji, required this.title,
      required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
    title: Text(title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(sub,
        style: const TextStyle(fontSize: 12, color: Colors.grey)),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

// ── Badge ──────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
        color: color.withAlpha(30), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color)),
  );
}

// ── Coach Debt Card ────────────────────────────────────────────────────────────
class _CoachDebtCard extends StatelessWidget {
  final int count;
  final AppRepository repo;
  const _CoachDebtCard({required this.count, required this.repo});

  @override
  Widget build(BuildContext context) {
    final accentColor = count == 0 ? AppColors.accent : AppColors.makeup;
    return GestureDetector(
      onTap: count == 0 ? null : () => _showDebtSheet(context),
      child: _MiniCard(
        title: 'طلب از استاد', accentColor: accentColor,
        child: count == 0
            ? const Row(children: [
                Text('✅', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('طلبی از استاد ندارید',
                    style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(JalaliHelper.toPersianDigits(count.toString()),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                        color: accentColor)),
                const SizedBox(width: 8),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('جلسه طلب دارید',
                      style: TextStyle(fontSize: 11, color: accentColor,
                          fontWeight: FontWeight.w600)),
                  const Text('برای مشاهده لمس کنید',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ])),
                Icon(Icons.chevron_left, color: accentColor.withAlpha(150),
                    size: 18),
              ]),
      ),
    );
  }

  void _showDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoachDebtSheet(repo: repo),
    );
  }
}

class _CoachDebtSheet extends StatelessWidget {
  final AppRepository repo;
  const _CoachDebtSheet({required this.repo});

  String _reasonLabel(SessionStatus s) {
    switch (s) {
      case SessionStatus.cancelledByCoach: return 'لغو توسط مربی';
      case SessionStatus.weather:          return 'آب‌وهوا / باران';
      case SessionStatus.holiday:          return 'تعطیل غیررسمی';
      default:                             return s.label;
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9,
    builder: (ctx, scroll) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Text('🧾', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('طلب از استاد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark)),
              Text('جلساتی که استاد لغو کرده',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Session>>(
            future: repo.sessionRepo.getCoachDebtSessions(),
            builder: (c, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(
                    color: AppColors.makeup));
              }
              final sessions = snap.data!;
              if (sessions.isEmpty) {
                return const Center(child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                  Text('✅', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('طلبی از استاد ندارید',
                      style: TextStyle(color: Colors.grey)),
                ]));
              }
              return ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final date = DateTime.tryParse(s.scheduledDate);
                  final jalali = date != null ? _safeJalali(date) : null;
                  final weekDay = date != null
                      ? JalaliHelper.weekDays[(date.weekday - 1) % 7] : '';
                  final dateLabel = jalali != null
                      ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} '
                        '${JalaliHelper.monthName(jalali.month)} '
                        '${JalaliHelper.toPersianDigits(jalali.year.toString())}'
                      : s.scheduledDate;
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.makeup.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.makeup.withAlpha(50)),
                    ),
                    child: ListTile(
                      leading: Text(s.status.emoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(dateLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Text(_reasonLabel(s.status),
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.makeup)),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(
                                  sessionId: s.id!, repo: repo)));
                        },
                        child: const Text('ویرایش',
                            style: TextStyle(color: AppColors.primary,
                                fontSize: 12)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    ),
  );
}

// ── Finance Card ───────────────────────────────────────────────────────────────
class _FinanceCard extends StatelessWidget {
  final dynamic pkg;
  const _FinanceCard({required this.pkg});
  @override
  Widget build(BuildContext context) {
    final debt = (pkg?.debt as int?) ?? 0;
    final overpaid = pkg != null && pkg.paidAmount > pkg.price
        ? (pkg.paidAmount as int) - (pkg.price as int)
        : 0;
    return _MiniCard(
      title: 'وضعیت مالی',
      accentColor: debt > 0 ? AppColors.debt
          : overpaid > 0 ? AppColors.makeup : AppColors.accent,
      child: debt == 0 && overpaid == 0
          ? const Row(children: [
              Text('✅', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('تسویه شده',
                  style: TextStyle(fontSize: 13, color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ])
          : overpaid > 0
              ? Row(children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${JalaliHelper.formatAmount(overpaid)} تومان',
                        style: const TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.makeup)),
                    const Text('بیشتر واریز کردی — از استادت طلبکاری',
                        style: TextStyle(fontSize: 10,
                            color: AppColors.makeup)),
                  ])),
                ])
              : Row(children: [
                  Text(JalaliHelper.formatAmount(debt),
                      style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: AppColors.debt)),
                  const SizedBox(width: 6),
                  const Text('تومان\nبدهی',
                      style: TextStyle(fontSize: 11, color: AppColors.debt,
                          height: 1.3)),
                ]),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  const _MiniCard({required this.title, required this.accentColor,
      required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border(right: BorderSide(color: accentColor, width: 3)),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey,
          fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

// ── Utility ───────────────────────────────────────────────────────────────────
dynamic _safeJalali(DateTime date) {
  try { return JalaliHelper.toJalali(date); } catch (_) { return null; }
}
