import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindBeforeClass = true;
  bool _remindMissedSession = true;
  bool _monthlyReport = false;
  int _reminderMinutes = 60; // دقیقه قبل از کلاس

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('تنظیمات نوتیفیکیشن',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _InfoBanner(),
          const SizedBox(height: 16),

          _SettingsCard(title: 'یادآوری جلسات', children: [
            _ToggleTile(
              icon: Icons.alarm_outlined,
              title: 'یادآوری قبل از کلاس',
              subtitle: 'قبل از شروع جلسه اطلاع‌رسانی می‌شه',
              value: _remindBeforeClass,
              onChanged: (v) => setState(() => _remindBeforeClass = v),
            ),
            if (_remindBeforeClass) ...[
              const Divider(height: 1, indent: 56),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  const SizedBox(width: 40),
                  const Text('چه موقع؟',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const Spacer(),
                  DropdownButton<int>(
                    value: _reminderMinutes,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('۳۰ دقیقه قبل')),
                      DropdownMenuItem(value: 60, child: Text('۱ ساعت قبل')),
                      DropdownMenuItem(value: 120, child: Text('۲ ساعت قبل')),
                      DropdownMenuItem(value: 1440, child: Text('یک روز قبل')),
                    ],
                    onChanged: (v) => setState(() => _reminderMinutes = v!),
                  ),
                ]),
              ),
            ],
            const Divider(height: 1, indent: 56),
            _ToggleTile(
              icon: Icons.history_outlined,
              title: 'یادآوری جلسات فراموش‌شده',
              subtitle: 'اگر جلسه‌ای بدون ثبت بماند اطلاع می‌ده',
              value: _remindMissedSession,
              onChanged: (v) => setState(() => _remindMissedSession = v),
            ),
          ]),
          const SizedBox(height: 14),

          _SettingsCard(title: 'گزارش‌ها', children: [
            _ToggleTile(
              icon: Icons.calendar_month_outlined,
              title: 'گزارش ماهانه',
              subtitle: 'اول هر ماه خلاصه جلسات ارسال می‌شه',
              value: _monthlyReport,
              onChanged: (v) => setState(() => _monthlyReport = v),
            ),
          ]),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('ذخیره تنظیمات', style: TextStyle(fontSize: 16)),
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    // ذخیره تنظیمات
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('تنظیمات ذخیره شد'),
        ]),
        backgroundColor: AppColors.accent,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primary.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withAlpha(50)),
    ),
    child: const Row(children: [
      Text('🔔', style: TextStyle(fontSize: 22)),
      SizedBox(width: 10),
      Expanded(child: Text(
        'یادآوری‌ها به موقع به تلفنت می‌رسن تا هیچ جلسه‌ای رو از دست ندی.',
        style: TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.5),
      )),
    ]),
  );
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
        color: AppColors.primaryDark)),
    const SizedBox(height: 8),
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6),
            blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 56),
          children[i],
        ],
      ]),
    ),
  ]);
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.title,
      required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: AppColors.primary),
    ),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    value: value,
    onChanged: onChanged,
    activeThumbColor: AppColors.primary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}
