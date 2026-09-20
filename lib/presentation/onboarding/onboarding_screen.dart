import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_helper.dart';
import '../../data/models/player.dart';
import '../../data/models/session.dart';
import '../../data/models/training_package.dart';
import '../../data/repositories/app_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  // ── مرحله ۱: اطلاعات بازیکن ───────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ── مرحله ۲: اطلاعات مربی ────────────────────────────────────────────────
  final _coachCtrl      = TextEditingController();
  final _clubCtrl       = TextEditingController();
  final _coachPhoneCtrl = TextEditingController();
  final _coachCardCtrl  = TextEditingController();

  // ── مرحله ۳: برنامه تمرینی ───────────────────────────────────────────────
  String _daysMode = 'custom';
  final Set<String> _selectedDays = {};
  TimeOfDay _trainingTime = const TimeOfDay(hour: 17, minute: 0);
  int _sessionDuration = 60;
  int _classParticipants = 1; // تعداد نفرات کلاس ۱-۶

  // ── مرحله ۴: اطلاعات پکیج ────────────────────────────────────────────────
  final _pkgNameCtrl  = TextEditingController(text: 'دوره تمرینی');
  final _pkgCountCtrl = TextEditingController(text: '8');
  final _pkgPriceCtrl = TextEditingController();
  String? _pkgStartDate;

  bool _saving = false;
  static const _totalSteps = 5;

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _coachCtrl.dispose(); _clubCtrl.dispose();
    _coachPhoneCtrl.dispose(); _coachCardCtrl.dispose();
    _pkgNameCtrl.dispose(); _pkgCountCtrl.dispose(); _pkgPriceCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalSteps - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _ctrl.previousPage(duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      setState(() => _page--);
    }
  }

  bool get _canNext {
    switch (_page) {
      case 0: return _nameCtrl.text.trim().isNotEmpty;
      case 1: return _coachCtrl.text.trim().isNotEmpty;
      case 2: return _daysMode != 'custom' || _selectedDays.isNotEmpty;
      case 3: return _pkgNameCtrl.text.trim().isNotEmpty &&
                     int.tryParse(_pkgCountCtrl.text) != null;
      case 4: return true;
      default: return false;
    }
  }

  // ── finish + auto-schedule ─────────────────────────────────────────────────
  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = context.read<AppRepository>();

    try {
      final days = (_daysMode == 'odd' || _daysMode == 'even')
          ? _daysMode
          : jsonEncode(_selectedDays.toList());
      final timeStr =
          '${_trainingTime.hour.toString().padLeft(2, '0')}:${_trainingTime.minute.toString().padLeft(2, '0')}';

      // ذخیره بازیکن
      final player = Player(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        coachName: _coachCtrl.text.trim(),
        coachPhone: _coachPhoneCtrl.text.trim().isEmpty ? null : _coachPhoneCtrl.text.trim(),
        coachCardNumber: _coachCardCtrl.text.trim().isEmpty ? null : _coachCardCtrl.text.trim(),
        clubName: _clubCtrl.text.trim().isEmpty ? null : _clubCtrl.text.trim(),
        trainingDays: days,
        trainingTime: timeStr,
        sessionDuration: _sessionDuration,
        classParticipants: _classParticipants,
      );

      // قیمت واقعی (سهم من)
      final totalPrice = int.tryParse(_pkgPriceCtrl.text.replaceAll(',', '')) ?? 0;
      final myShare = _classParticipants > 1
          ? (totalPrice / _classParticipants).round()
          : totalPrice;

      final today = JalaliHelper.today;
      final startDate = _pkgStartDate ??
          JalaliHelper.toJalaliIso(today.year, today.month, today.day);

      final pkg = TrainingPackage(
        name: _pkgNameCtrl.text.trim(),
        totalSessions: int.tryParse(_pkgCountCtrl.text) ?? 12,
        price: myShare,
        startDate: startDate,
        createdAt: DateTime.now().toIso8601String(),
      );
      final sessions = _buildSchedule(startDate, timeStr, pkg.totalSessions);
      await repo.completeOnboarding(
        player: player, package: pkg, sessions: sessions,
      );
      // AppRoot shows the main screen when the saved profile is complete.
    } catch (error, stackTrace) {
      debugPrint('Unable to complete onboarding (${error.runtimeType}).');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ذخیره اطلاعات انجام نشد. لطفاً دوباره تلاش کنید.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Session> _buildSchedule(String startJalaliIso,
      String timeStr, int totalCount) {
    // نگاشت کد روز → weekday داخلی Dart (1=Mon .. 6=Sat, 7=Sun)
    const dayToWeekday = {
      'sat': 6, 'sun': 7, 'mon': 1, 'tue': 2,
      'wed': 3, 'thu': 4, 'fri': 5,
    };

    final startGreg = JalaliHelper.parseJalaliDate(startJalaliIso).toDateTime();
    final sessions = <Session>[];
    final nowIso = DateTime.now().toIso8601String();
    final limit = startGreg.add(const Duration(days: 400));

    int count = 0;
    DateTime cur = startGreg;

    while (count < totalCount && cur.isBefore(limit)) {
      bool matches;
      if (_daysMode == 'odd' || _daysMode == 'even') {
        final j = JalaliHelper.toJalali(cur);
        matches = (_daysMode == 'odd') ? (j.day % 2 == 1) : (j.day % 2 == 0);
      } else {
        matches = _selectedDays.any((d) => dayToWeekday[d] == cur.weekday);
      }

      if (matches) {
        final j = JalaliHelper.toJalali(cur);
        sessions.add(Session(
          scheduledDate: cur.toIso8601String().substring(0, 10),
          jalaliYear:  j.year,
          jalaliMonth: j.month,
          time: timeStr,
          duration: _sessionDuration,
          status: SessionStatus.upcoming,
          createdAt: nowIso,
        ));
        count++;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return sessions;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildProgress(),
          Expanded(
            child: PageView(
              controller: _ctrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
                _buildStep5(),
              ],
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.sports_tennis, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('دستیار تنیس',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.primaryDark)),
        Text('مرحله ${JalaliHelper.toPersianDigits((_page + 1).toString())} از ${JalaliHelper.toPersianDigits(_totalSteps.toString())}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    ]),
  );

  Widget _buildProgress() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(children: List.generate(_totalSteps, (i) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: i <= _page ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    ))),
  );

  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Row(children: [
      if (_page > 0) ...[
        OutlinedButton(
          onPressed: _saving ? null : _back,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColors.primary),
          ),
          child: const Text('قبلی', style: TextStyle(color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: FilledButton(
          onPressed: (_canNext && !_saving) ? _next : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _saving
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_page == _totalSteps - 1 ? 'شروع کنید' : 'بعدی',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    ]),
  );

  // ── Step 1: اطلاعات بازیکن ─────────────────────────────────────────────────
  Widget _buildStep1() => _StepScroll(
    title: 'اطلاعات تنیسور',
    subtitle: 'نام خود را وارد کنید',
    icon: Icons.person_outline,
    child: _field(_nameCtrl, 'نام شما *', Icons.badge_outlined,
        onChanged: (_) => setState(() {})),
  );

  // ── Step 2: اطلاعات مربی ──────────────────────────────────────────────────
  Widget _buildStep2() => _StepScroll(
    title: 'اطلاعات مربی',
    subtitle: 'مربی و باشگاه خود را معرفی کنید',
    icon: Icons.sports_outlined,
    child: Column(children: [
      _field(_coachCtrl, 'نام مربی *', Icons.person_pin_outlined,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 14),
      _field(_clubCtrl, 'نام باشگاه / آکادمی (اختیاری)',
          Icons.location_on_outlined),
      const SizedBox(height: 14),
      _field(_coachPhoneCtrl, 'شماره تماس مربی (اختیاری)', Icons.phone_outlined,
          keyboardType: TextInputType.phone),
      const SizedBox(height: 14),
      _field(_coachCardCtrl, 'شماره کارت مربی (اختیاری)',
          Icons.credit_card_outlined, keyboardType: TextInputType.number),
    ]),
  );

  // ── Step 3: برنامه تمرینی ─────────────────────────────────────────────────
  Widget _buildStep3() => _StepScroll(
    title: 'کلاس‌های شما',
    subtitle: 'کلاس‌های شما چه روزهایی برگزار می‌شه؟',
    icon: Icons.calendar_month_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _modeChip('روزهای زوج', 'even'),
        _modeChip('روزهای فرد', 'odd'),
        _modeChip('انتخاب دستی', 'custom'),
      ]),
      const SizedBox(height: 12),
      if (_daysMode == 'custom') _dayPicker(),
      const SizedBox(height: 20),
      const Text('ساعت برگزاری کلاس',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 10),
      _dateTile(
        label: '${_trainingTime.hour.toString().padLeft(2, '0')}:${_trainingTime.minute.toString().padLeft(2, '0')}',
        icon: Icons.access_time_outlined,
        onTap: () async {
          final t = await showTimePicker(context: context,
              initialTime: _trainingTime);
          if (t != null) setState(() => _trainingTime = t);
        },
      ),
      const SizedBox(height: 20),
      const Text('مدت هر جلسه',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        for (final v in [45, 60, 90])
          ChoiceChip(
            label: Text('$v دقیقه'),
            selected: _sessionDuration == v,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
                color: _sessionDuration == v ? Colors.white : Colors.black87),
            onSelected: (_) => setState(() => _sessionDuration = v),
          ),
      ]),
      const SizedBox(height: 20),
      const Text('تعداد نفرات کلاس',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 4),
      const Text('هزینه کلاس بین این تعداد نفر تقسیم می‌شود',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: List.generate(6, (i) {
        final v = i + 1;
        final sel = _classParticipants == v;
        return GestureDetector(
          onTap: () => setState(() => _classParticipants = v),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sel ? AppColors.primary : Colors.grey.shade200,
              border: sel ? null : Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(JalaliHelper.toPersianDigits(v.toString()),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.white : Colors.black87)),
          ),
        );
      })),
    ]),
  );

  // ── Step 4: دوره تمرینی ───────────────────────────────────────────────────
  Widget _buildStep4() => _StepScroll(
    title: 'دوره تمرینی',
    subtitle: 'مشخصات دوره کلاس خود را وارد کنید',
    icon: Icons.event_note_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // تاریخ شروع
      const Text('تاریخ شروع اولین جلسه کلاس',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 10),
      _dateTile(
        label: _pkgStartDate == null
            ? 'انتخاب تاریخ (پیش‌فرض: امروز)'
            : JalaliHelper.formatJalaliIsoLong(_pkgStartDate!),
        icon: Icons.event_outlined,
        onTap: () async {
          final d = await _pickJalaliDate(context);
          if (d != null) setState(() => _pkgStartDate = d);
        },
      ),

      const SizedBox(height: 24),

      // تعداد جلسات در ماه — استپر بزرگ
      const Text('تعداد جلسات کلاس در ماه',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // دکمه کم
          GestureDetector(
            onTap: () {
              final v = int.tryParse(_pkgCountCtrl.text) ?? 8;
              if (v > 1) setState(() => _pkgCountCtrl.text = (v - 1).toString());
            },
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
              child: const Icon(Icons.remove, color: AppColors.primary, size: 28),
            ),
          ),
          // عدد
          Column(children: [
            Text(
              JalaliHelper.toPersianDigits(_pkgCountCtrl.text.isEmpty ? '8' : _pkgCountCtrl.text),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark),
            ),
            const Text('جلسه در ماه', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          // دکمه زیاد
          GestureDetector(
            onTap: () {
              final v = int.tryParse(_pkgCountCtrl.text) ?? 8;
              setState(() => _pkgCountCtrl.text = (v + 1).toString());
            },
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 28),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 24),

      // هزینه دوره
      const Text('هزینه هر دوره کلاس (تومان)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 10),
      _field(_pkgPriceCtrl, 'مبلغ را وارد کنید', Icons.payments_outlined,
          keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
      if (_classParticipants > 1 && _pkgPriceCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.group_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'سهم شما: ${_calcMyShare()} تومان  (${JalaliHelper.toPersianDigits(_classParticipants.toString())} نفره)',
                style: const TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ]),
        ),
      ],

      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withAlpha(60)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('چینش خودکار جلسات',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: AppColors.accent, fontSize: 13)),
              SizedBox(height: 4),
              Text('بر اساس روزها و ساعت کلاس، جلسات به‌صورت خودکار در تقویم ثبت می‌شوند.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
            ]),
          ),
        ]),
      ),
    ]),
  );

  // ── Step 5: تأیید ─────────────────────────────────────────────────────────
  Widget _buildStep5() {
    final timeStr =
        '${_trainingTime.hour.toString().padLeft(2, '0')}:${_trainingTime.minute.toString().padLeft(2, '0')}';
    final daysLabel = _daysMode == 'custom'
        ? _selectedDays.map((d) => const {
            'sat': 'شنبه', 'sun': 'یکشنبه', 'mon': 'دوشنبه',
            'tue': 'سه‌شنبه', 'wed': 'چهارشنبه', 'thu': 'پنجشنبه',
            'fri': 'جمعه'}[d] ?? d).join('، ')
        : (_daysMode == 'odd' ? 'روزهای فرد' : 'روزهای زوج');

    return _StepScroll(
      title: 'تأیید اطلاعات',
      subtitle: 'همه چیز درست است؟',
      icon: Icons.check_circle_outline,
      child: Column(children: [
        _reviewSection('بازیکن', [
          ('نام', _nameCtrl.text.trim()),
          if (_phoneCtrl.text.trim().isNotEmpty)
            ('موبایل', _phoneCtrl.text.trim()),
        ]),
        _reviewSection('مربی', [
          ('مربی', _coachCtrl.text.trim()),
          if (_clubCtrl.text.trim().isNotEmpty)
            ('باشگاه', _clubCtrl.text.trim()),
          if (_coachPhoneCtrl.text.trim().isNotEmpty)
            ('تلفن مربی', _coachPhoneCtrl.text.trim()),
          if (_coachCardCtrl.text.trim().isNotEmpty)
            ('کارت مربی', _coachCardCtrl.text.trim()),
        ]),
        _reviewSection('برنامه', [
          ('روزها', daysLabel),
          ('ساعت', timeStr),
          ('مدت', '$_sessionDuration دقیقه'),
          ('نفرات', '${JalaliHelper.toPersianDigits(_classParticipants.toString())} نفر'),
        ]),
        _reviewSection('دوره تمرینی', [
          ('جلسات ماهانه', '${JalaliHelper.toPersianDigits(_pkgCountCtrl.text)} جلسه'),
          if (_pkgStartDate != null)
            ('شروع', JalaliHelper.formatJalaliIsoLong(_pkgStartDate!)),
          if (_pkgPriceCtrl.text.isNotEmpty)
            ('سهم شما', '${_calcMyShare()} تومان'),
        ]),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: const [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text('جلسات به‌صورت خودکار در تقویم ثبت می‌شوند ✓',
                  style: TextStyle(fontSize: 12, color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _calcMyShare() {
    final total = int.tryParse(_pkgPriceCtrl.text.replaceAll(',', '')) ?? 0;
    final share = _classParticipants > 1
        ? (total / _classParticipants).round()
        : total;
    return JalaliHelper.formatAmount(share);
  }

  Widget _modeChip(String label, String value) => FilterChip(
    label: Text(label, style: const TextStyle(fontSize: 15)),
    selected: _daysMode == value,
    selectedColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    labelStyle: TextStyle(
        color: _daysMode == value ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600),
    onSelected: (_) => setState(() {
      _daysMode = value;
      if (value != 'custom') _selectedDays.clear();
    }),
  );

  Widget _dayPicker() {
    const days = [
      ('sat', 'ش'), ('sun', 'ی'), ('mon', 'د'), ('tue', 'س'),
      ('wed', 'چ'), ('thu', 'پ'), ('fri', 'ج'),
    ];
    return Wrap(spacing: 8, children: days.map(((String, String) rec) {
      final selected = _selectedDays.contains(rec.$1);
      return GestureDetector(
        onTap: () => setState(() {
          if (selected) _selectedDays.remove(rec.$1);
          else          _selectedDays.add(rec.$1);
        }),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.primary : Colors.grey.shade200,
          ),
          alignment: Alignment.center,
          child: Text(rec.$2,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }).toList());
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, void Function(String)? onChanged}) =>
    TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

  Widget _dateTile({required String label, required IconData icon,
      required VoidCallback onTap}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(color: Colors.black87))),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ]),
      ),
    );

  Widget _reviewSection(String title, List<(String, String)> items) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold,
                color: AppColors.primary, fontSize: 13)),
        const Divider(height: 12),
        ...items.map(((String, String) r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text('${r.$1}:',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 8),
            Text(r.$2,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ]),
        )),
      ]),
    );

  Future<String?> _pickJalaliDate(BuildContext context) async {
    final today = JalaliHelper.today;
    int year = today.year, month = today.month, day = today.day;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('انتخاب تاریخ'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Text('سال:'), const Spacer(),
              IconButton(icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => ss(() => year--)),
              Text(JalaliHelper.toPersianDigits(year.toString())),
              IconButton(icon: const Icon(Icons.add, size: 18),
                  onPressed: () => ss(() => year++)),
            ]),
            Row(children: [
              const Text('ماه:'), const Spacer(),
              IconButton(icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => ss(() {
                    if (month > 1) month--; else { month = 12; year--; }
                  })),
              Text(JalaliHelper.monthName(month)),
              IconButton(icon: const Icon(Icons.add, size: 18),
                  onPressed: () => ss(() {
                    if (month < 12) month++; else { month = 1; year++; }
                  })),
            ]),
            Row(children: [
              const Text('روز:'), const Spacer(),
              IconButton(icon: const Icon(Icons.remove, size: 18),
                  onPressed: () => ss(() {
                    if (day > 1) day--; else day = 29;
                  })),
              Text(JalaliHelper.toPersianDigits(day.toString())),
              IconButton(icon: const Icon(Icons.add, size: 18),
                  onPressed: () => ss(() {
                    if (day < 29) day++; else day = 1;
                  })),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('لغو')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx,
                  JalaliHelper.toJalaliIso(year, month, day)),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared step wrapper ────────────────────────────────────────────────────────
class _StepScroll extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget child;
  const _StepScroll({required this.title, required this.subtitle,
      required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
      const SizedBox(height: 14),
      Text(title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
              color: AppColors.primaryDark)),
      const SizedBox(height: 6),
      Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 24),
      child,
    ]),
  );
}
