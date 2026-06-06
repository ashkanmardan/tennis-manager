import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/app_repository.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final j = JalaliHelper.today;
    _currentYear = j.year;
    _currentMonth = j.month;
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final sessions = repo
        .getSessionsForJalaliMonth(_currentYear, _currentMonth)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('جلسات'),
      ),
      body: Column(
        children: [
          // Month navigator
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: Text(
                    '${JalaliHelper.monthName(_currentMonth)} ${JalaliHelper.toPersianDigits(_currentYear.toString())}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryChip(
                  label: 'کل',
                  value: sessions.length,
                  color: Colors.blue,
                ),
                _SummaryChip(
                  label: 'عادی',
                  value: sessions.where((s) => s.isRegular && !s.coachCancelled).length,
                  color: Colors.green,
                ),
                _SummaryChip(
                  label: 'جبرانی',
                  value: sessions.where((s) => s.isMakeup).length,
                  color: Colors.orange,
                ),
                _SummaryChip(
                  label: 'لغو‌شده',
                  value: sessions.where((s) => s.coachCancelled).length,
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // Sessions list
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('جلسه‌ای در این ماه ثبت نشده',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sessions.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (ctx, i) {
                      final session = sessions[i];
                      return _SessionCard(session: session);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSession(context),
        icon: const Icon(Icons.add),
        label: const Text('جلسه جدید'),
      ),
    );
  }

  void _addSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSessionSheet(
        initialYear: _currentYear,
        initialMonth: _currentMonth,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          JalaliHelper.toPersianDigits(value.toString()),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String typeLabel;

    if (session.coachCancelled) {
      color = Colors.red;
      icon = Icons.cancel;
      typeLabel = 'لغو شده توسط مربی';
    } else if (session.isMakeup) {
      color = Colors.orange;
      icon = Icons.repeat;
      typeLabel = 'جلسه جبرانی';
    } else {
      color = const Color(0xFF2E7D32);
      icon = Icons.sports_tennis;
      typeLabel = 'جلسه عادی';
    }

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: session),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      JalaliHelper.formatDateLong(session.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(fontSize: 11, color: color),
                          ),
                        ),
                        if (session.venue != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '📍 ${session.venue}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSessionSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _AddSessionSheet({required this.initialYear, required this.initialMonth});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final _venueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _sessionType = 'regular';
  bool _coachCancelled = false;
  bool _requiresMakeup = false;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _venueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Simple date picker - use Gregorian but display Jalali
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fa'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = context.read<AppRepository>();
      final session = Session(
        date: _selectedDate,
        sessionType: _sessionType,
        coachId: repo.activeCoach?.id,
        venue: _venueCtrl.text.isEmpty ? null : _venueCtrl.text,
        coachCancelled: _coachCancelled,
        requiresMakeup: _requiresMakeup,
        notes: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        createdAt: DateTime.now(),
      );
      await repo.addSession(session);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ثبت جلسه',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date picker
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Text(JalaliHelper.formatDateLong(_selectedDate),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Session type
            const Text('نوع جلسه', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'regular',
                    groupValue: _sessionType,
                    onChanged: (v) => setState(() => _sessionType = v!),
                    title: const Text('عادی'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'makeup',
                    groupValue: _sessionType,
                    onChanged: (v) => setState(() => _sessionType = v!),
                    title: const Text('جبرانی'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            // Coach cancelled
            SwitchListTile(
              value: _coachCancelled,
              onChanged: (v) => setState(() {
                _coachCancelled = v;
                if (!v) _requiresMakeup = false;
              }),
              title: const Text('لغو شده توسط مربی'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_coachCancelled)
              SwitchListTile(
                value: _requiresMakeup,
                onChanged: (v) => setState(() => _requiresMakeup = v),
                title: const Text('نیاز به جلسه جبرانی دارد'),
                contentPadding: EdgeInsets.zero,
              ),

            const SizedBox(height: 8),
            TextField(
              controller: _venueCtrl,
              decoration: const InputDecoration(
                labelText: 'مکان',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ثبت جلسه'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
