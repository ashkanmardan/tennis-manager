import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../core/utils/iranian_holidays.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/app_repository.dart';
import '../sessions/session_detail_screen.dart';
import '../../widgets/app_drawer.dart';

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
            _TealAppBar(playerName: playerName),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _TodayCard(repo: repo),
                  const SizedBox(height: 10),
                  // جلسه بعدی + جلسه قبلی
                  _NextSessionCard(session: repo.nextSession, repo: repo),
                  const SizedBox(height: 10),
                  _PrevSessionCard(session: repo.lastSession, repo: repo),
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

// ── App Bar ───────────────────────────────────────────────────────────────────
class _TealAppBar extends StatelessWidget {
  final String playerName;
  const _TealAppBar({required this.playerName});

  @override
  Widget build(BuildContext context) {
    final jalali = JalaliHelper.today;
    final weekDay = JalaliHelper.weekDays[(jalali.weekDay - 1) % 7];
    final dayNum = JalaliHelper.toPersianDigits(jalali.day.toString());
    final monthN = JalaliHelper.monthName(jalali.month);
    final dateStr = '$weekDay $dayNum $monthN';

    return SliverAppBar(
      backgroundColor: AppColors.primaryDark,
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      // دکمه همبرگر برجسته‌تر
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _CourtPainter()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 60, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ردیف سلام + تاریخ
                    Row(children: [
                      // تاریخ — سمت چپ
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(dateStr,
                            style: const TextStyle(fontSize: 12, color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(JalaliHelper.toPersianDigits(jalali.year.toString()),
                            style: const TextStyle(fontSize: 10, color: Colors.white38)),
                      ]),
                      // سلام — وسط
                      Expanded(
                        child: Text(
                          'سلام $playerName! 👋',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ]),
                    const Spacer(),
                    _StatsStrip(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

// ── Stats Strip ───────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final pkg = repo.activePackage;
    final debt = pkg?.debt ?? 0;
    final completed = pkg?.completedSessions ?? 0;
    final total = pkg?.totalSessions ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(70),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _StatItem(label: 'جلسه ماه',
            value: JalaliHelper.toPersianDigits(completed.toString()),
            valueColor: AppColors.neonGreen),
        _divider(),
        _StatItem(label: 'دوره',
            value: total == 0 ? '—'
                : '${JalaliHelper.toPersianDigits(completed.toString())}/${JalaliHelper.toPersianDigits(total.toString())}'),
        _divider(),
        _StatItem(label: 'بدهی',
            value: debt == 0 ? 'تسویه' : '${JalaliHelper.formatAmount(debt)}ت',
            valueColor: debt > 0 ? const Color(0xFFFFB3A7) : AppColors.neonGreen),
      ]),
    );
  }
  Widget _divider() => Container(width: 1, height: 32, color: Colors.white24);
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _StatItem({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white54)),
      ]),
    ),
  );
}

// ── Today Banner (جلسه امروز) ─────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final AppRepository repo;
  const _TodayCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final session = repo.nextSession;
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);
    if (session == null || session.scheduledDate.substring(0, 10) != todayIso) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFF0A7A5E)],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.accent.withAlpha(60),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Text('🎾', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('امروز کلاس داری!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          if (session.time != null)
            Text('ساعت ${session.time} · ${session.duration} دقیقه',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ── Next Session Card (جلسه بعدی با سوال) ────────────────────────────────────
class _NextSessionCard extends StatefulWidget {
  final Session? session;
  final AppRepository repo;
  const _NextSessionCard({required this.session, required this.repo});
  @override
  State<_NextSessionCard> createState() => _NextSessionCardState();
}

class _NextSessionCardState extends State<_NextSessionCard> {
  bool _busy = false;

  Future<void> _mark(SessionStatus status, {String? notes}) async {
    if (widget.session?.id == null) return;
    setState(() => _busy = true);
    await widget.repo.updateSessionStatus(widget.session!.id!, status, notes: notes);
    if (mounted) setState(() => _busy = false);
  }

  void _showCancel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(
        onSelect: (s, n) => _mark(s, notes: n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) return _noSession();
    final s = widget.session!;
    final dateTime = DateTime.tryParse(s.scheduledDate);
    final jalali = dateTime != null ? JalaliHelper.toJalali(dateTime) : null;
    final weekDay = dateTime != null
        ? JalaliHelper.weekDays[(dateTime.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} ${JalaliHelper.monthName(jalali.month)}'
        : '---';
    final now = DateTime.now();
    final diff = dateTime != null ? dateTime.difference(now) : Duration.zero;

    final isCompleted = s.status == SessionStatus.completed;
    final isCancelled = s.status != SessionStatus.upcoming &&
        s.status != SessionStatus.completed;

    final isHoliday = jalali != null &&
        IranianHolidays.isHoliday(s.scheduledDate, jalali.month, jalali.day);
    final accentColor = isHoliday ? const Color(0xFFE91E8C) : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: accentColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // اطلاعات جلسه
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.event_note_outlined, color: accentColor, size: 13),
                const SizedBox(width: 4),
                const Text('جلسه بعدی', style: TextStyle(fontSize: 11, color: Colors.grey)),
                if (s.isMakeup) ...[
                  const SizedBox(width: 6),
                  _Badge('جبرانی', AppColors.makeup),
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
              child: Text(_countdown(diff),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor)),
            ),
          ]),
        ),
        // خط جداکننده
        Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 14)),
        // سوال + دکمه‌ها
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(children: [
            const Text('آیا این کلاس برگزار می‌شه؟',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _busy
                ? const SizedBox(height: 40,
                    child: Center(child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)))
                : Row(children: [
                    Expanded(child: _QuestionBtn(
                      label: '✅  بله، برگزار می‌شه',
                      selected: isCompleted,
                      selectedColor: AppColors.accent,
                      onTap: () => _mark(SessionStatus.completed),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _QuestionBtn(
                      label: '❌  خیر، لغو می‌شه',
                      selected: isCancelled,
                      selectedColor: Colors.red.shade400,
                      onTap: _showCancel,
                    )),
                  ]),
          ]),
        ),
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
        Text('جلسه‌ای برنامه‌ریزی نشده', style: TextStyle(color: Colors.grey, fontSize: 13)),
        Text('از تب جلسات اضافه کنید', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    ]),
  );
}

// ── Prev Session Card (جلسه قبلی با سوال) ────────────────────────────────────
class _PrevSessionCard extends StatefulWidget {
  final Session? session;
  final AppRepository repo;
  const _PrevSessionCard({required this.session, required this.repo});
  @override
  State<_PrevSessionCard> createState() => _PrevSessionCardState();
}

class _PrevSessionCardState extends State<_PrevSessionCard> {
  bool _busy = false;

  Future<void> _mark(SessionStatus status, {String? notes}) async {
    if (widget.session?.id == null) return;
    setState(() => _busy = true);
    await widget.repo.updateSessionStatus(widget.session!.id!, status, notes: notes);
    if (mounted) setState(() => _busy = false);
  }

  void _showCancel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(
        onSelect: (s, n) => _mark(s, notes: n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            border: Border(right: BorderSide(color: Colors.grey.shade300, width: 4))),
        child: Row(children: [
          Icon(Icons.history, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          const Text('هنوز جلسه‌ای ثبت نشده',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
    }

    final s = widget.session!;
    final dateTime = DateTime.tryParse(s.scheduledDate);
    final jalali = dateTime != null ? JalaliHelper.toJalali(dateTime) : null;
    final weekDay = dateTime != null
        ? JalaliHelper.weekDays[(dateTime.weekday - 1) % 7] : '';
    final dateLabel = jalali != null
        ? '$weekDay ${JalaliHelper.toPersianDigits(jalali.day.toString())} ${JalaliHelper.monthName(jalali.month)}'
        : '---';

    final isCompleted = s.status == SessionStatus.completed;
    final isCancelled = !isCompleted && s.status != SessionStatus.upcoming;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: AppColors.accent.withAlpha(150), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // اطلاعات جلسه
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.history, color: AppColors.accent.withAlpha(180), size: 13),
                const SizedBox(width: 4),
                const Text('جلسه قبلی', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              const SizedBox(height: 5),
              Text(dateLabel,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
              if (s.time != null)
                Text('ساعت ${s.time} · ${s.duration} دقیقه',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            // وضعیت فعلی
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isCompleted ? AppColors.accent : Colors.red.shade400).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(s.status.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ]),
        ),
        // خط جداکننده
        Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 14)),
        // سوال + دکمه‌ها
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(children: [
            const Text('وضعیت این جلسه چه بود؟',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _busy
                ? const SizedBox(height: 40,
                    child: Center(child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent)))
                : Row(children: [
                    Expanded(child: _QuestionBtn(
                      label: '✅  برگزار شد',
                      selected: isCompleted,
                      selectedColor: AppColors.accent,
                      onTap: () => _mark(SessionStatus.completed),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _QuestionBtn(
                      label: '❌  لغو شد',
                      selected: isCancelled,
                      selectedColor: Colors.red.shade400,
                      onTap: _showCancel,
                    )),
                  ]),
          ]),
        ),
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
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
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
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      const Text('علت لغو؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      _CancelOption(emoji: '❌', title: 'لغو توسط مربی', sub: 'جلسه جبرانی ثبت می‌شه',
          onTap: () { Navigator.pop(context); onSelect(SessionStatus.cancelledByCoach, null); }),
      _CancelOption(emoji: '🚫', title: 'لغو توسط من', sub: 'جلسه از دوره کسر می‌شه',
          onTap: () { Navigator.pop(context); onSelect(SessionStatus.cancelledByPlayer, null); }),
      _CancelOption(emoji: '🌧', title: 'آب‌وهوا / باران', sub: 'جلسه جبرانی ثبت می‌شه',
          onTap: () { Navigator.pop(context); onSelect(SessionStatus.weather, null); }),
      _CancelOption(emoji: '📅', title: 'تعطیل رسمی', sub: 'ثبت می‌شه بدون جبرانی',
          onTap: () { Navigator.pop(context); onSelect(SessionStatus.holiday, null); }),
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
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

// ── Mini Cards ────────────────────────────────────────────────────────────────

/// کارت طلب از استاد — جلساتی که مربی/آب‌وهوا/تعطیل غیررسمی لغو کرده
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
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('جلسه طلب دارید',
                      style: TextStyle(fontSize: 11, color: accentColor,
                          fontWeight: FontWeight.w600)),
                  const Text('برای مشاهده لمس کنید',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ])),
                Icon(Icons.chevron_left, color: accentColor.withAlpha(150), size: 18),
              ]),
      ),
    );
  }

  void _showDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoachDebtSheet(repo: repo),
    );
  }
}

/// شیت لیست جلسات طلب از استاد
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
    initialChildSize: 0.6,
    minChildSize: 0.4,
    maxChildSize: 0.9,
    builder: (ctx, scroll) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // دستگیره
        Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        // عنوان
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Text('🧾', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('طلب از استاد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark)),
              Text('جلساتی که استاد لغو کرده و بدهکار است',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(ctx),
            ),
          ]),
        ),
        const Divider(height: 1),
        // لیست
        Expanded(
          child: FutureBuilder<List<Session>>(
            future: repo.sessionRepo.getCoachDebtSessions(),
            builder: (c, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.makeup));
              }
              final sessions = snap.data!;
              if (sessions.isEmpty) {
                return const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('✅', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('طلبی از استاد ندارید', style: TextStyle(color: Colors.grey)),
                  ]),
                );
              }
              return ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final date = DateTime.tryParse(s.scheduledDate);
                  final jalali = date != null ? JalaliHelper.toJalali(date) : null;
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(_reasonLabel(s.status),
                          style: const TextStyle(fontSize: 11, color: AppColors.makeup)),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(
                                  sessionId: s.id!, repo: repo)));
                        },
                        child: const Text('ویرایش',
                            style: TextStyle(color: AppColors.primary, fontSize: 12)),
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

class _FinanceCard extends StatelessWidget {
  final dynamic pkg;
  const _FinanceCard({required this.pkg});
  @override
  Widget build(BuildContext context) {
    final debt = (pkg?.debt as int?) ?? 0;
    return _MiniCard(
      title: 'وضعیت مالی', accentColor: debt > 0 ? AppColors.debt : AppColors.accent,
      child: debt == 0
          ? const Row(children: [
              Text('✅', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('تسویه شده',
                  style: TextStyle(fontSize: 13, color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ])
          : Row(children: [
              Text(JalaliHelper.formatAmount(debt),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.debt)),
              const SizedBox(width: 6),
              const Text('تومان\nبدهی',
                  style: TextStyle(fontSize: 11, color: AppColors.debt, height: 1.3)),
            ]),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  const _MiniCard({required this.title, required this.accentColor, required this.child});
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
