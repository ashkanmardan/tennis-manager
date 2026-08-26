import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/models/session.dart';

class AddSessionSheet extends StatefulWidget {
  final AppRepository repo;
  const AddSessionSheet({super.key, required this.repo});
  @override
  State<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<AddSessionSheet> {
  late Jalali _selectedDate;
  TimeOfDay? _selectedTime;
  int  _duration = 60;
  bool _isMakeup = false;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = JalaliHelper.today;
    final player = widget.repo.player;
    if (player != null) {
      final parts = player.trainingTime.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 17,
            minute: int.tryParse(parts[1]) ?? 0);
      }
      _duration = player.sessionDuration;
    }
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final today = JalaliHelper.today;
    final dates = <Jalali>[];
    var d = Jalali(today.year - 1, 1, 1);
    final end = JalaliHelper.nextMonth(today.year, today.month);
    final endDate = Jalali(end['year']!, end['month']!, 1);
    while (d.julianDayNumber <= endDate.julianDayNumber) {
      dates.add(d);
      d = d.addDays(1);
    }
    final picked = await showDialog<Jalali>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('انتخاب تاریخ'),
        content: SizedBox(
          width: 280, height: 300,
          child: ListView.builder(
            itemCount: dates.length,
            itemBuilder: (_, i) {
              final date = dates[dates.length - 1 - i];
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppColors.primary.withAlpha(15),
                selectedColor: AppColors.primary,
                title: Text(
                  '${JalaliHelper.toPersianDigits(date.day.toString())} '
                  '${JalaliHelper.monthName(date.month)} '
                  '${JalaliHelper.toPersianDigits(date.year.toString())}'),
                onTap: () => Navigator.pop(ctx, date),
              );
            },
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dateStr = JalaliHelper.toDateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day)
          .toIso8601String().substring(0, 10);
      final timeStr = _selectedTime == null ? null
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final pkg = widget.repo.activePackage;
      await widget.repo.addSession(Session(
        scheduledDate: dateStr,
        jalaliYear: _selectedDate.year,
        jalaliMonth: _selectedDate.month,
        time: timeStr,
        duration: _duration,
        status: SessionStatus.upcoming,
        packageId: pkg?.id,
        isMakeup: _isMakeup,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${JalaliHelper.toPersianDigits(_selectedDate.day.toString())} '
        '${JalaliHelper.monthName(_selectedDate.month)} '
        '${JalaliHelper.toPersianDigits(_selectedDate.year.toString())}';
    final timeLabel = _selectedTime == null ? 'ساعت (اختیاری)'
        : '${_selectedTime!.hour.toString().padLeft(2, "0")}:'
          '${_selectedTime!.minute.toString().padLeft(2, "0")}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8, left: 16, right: 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const Text('ثبت جلسه جدید',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _TileBtn(icon: Icons.calendar_today_outlined, label: dateLabel, onTap: _pickDate),
          const SizedBox(height: 10),
          _TileBtn(
            icon: Icons.access_time_outlined,
            label: timeLabel,
            trailing: _selectedTime != null
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _selectedTime = null))
                : null,
            onTap: () async {
              final t = await showTimePicker(context: context,
                  initialTime: _selectedTime ?? const TimeOfDay(hour: 17, minute: 0));
              if (t != null) setState(() => _selectedTime = t);
            },
          ),
          const SizedBox(height: 10),
          _row(Icons.timer_outlined, 'مدت جلسه:',
            DropdownButton<int>(
              value: _duration,
              underline: const SizedBox(),
              items: [30, 45, 60, 90, 120]
                  .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('${JalaliHelper.toPersianDigits(v.toString())} دقیقه')))
                  .toList(),
              onChanged: (v) => setState(() => _duration = v!),
            ),
          ),
          const SizedBox(height: 6),
          _row(Icons.replay_outlined, 'جلسه جبرانی است',
            Switch(value: _isMakeup, activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isMakeup = v)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              labelText: 'یادداشت (اختیاری)',
              prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary)),
              filled: true, fillColor: const Color(0xFFF5F5F5),
            ),
            maxLines: 2,
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
                  : const Text('ذخیره جلسه', style: TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _handle() => Center(
    child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
  );

  Widget _row(IconData icon, String label, Widget trailing) => Row(children: [
    Icon(icon, color: Colors.grey, size: 20),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(fontSize: 15)),
    const Spacer(),
    trailing,
  ]);
}

class _TileBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _TileBtn({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF5F5F5),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        trailing ?? const Icon(Icons.arrow_drop_down, color: Colors.grey),
      ]),
    ),
  );
}
