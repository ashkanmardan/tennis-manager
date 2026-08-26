import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../screens/guide/guide_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/package/package_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/backup/backup_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topRight, end: Alignment.bottomLeft,
            ),
          ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4DE2C2), Color(0xFF0D6E8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Icon(Icons.sports_tennis, color: Colors.white, size: 30)),
          ),
            const SizedBox(height: 12),
            const Text('دستیار تنیس',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            const Text('منوی اصلی', style: TextStyle(fontSize: 12, color: Colors.white60)),
          ]),
        ),

        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [

            _DrawerSection(title: 'تمرین', children: [
              _DrawerItem(icon: Icons.class_outlined, label: 'زمان کلاس شما',
                  sub: 'وضعیت و پیشرفت کلاس',
                  onTap: () => _go(context, const PackageScreen())),
              _DrawerItem(icon: Icons.event_note_outlined, label: 'جلسات',
                  sub: 'مشاهده و ویرایش جلسات',
                  onTap: () => _go(context, const SessionsScreen())),
            ]),

            _DrawerSection(title: 'گزارش‌ها', children: [
              _DrawerItem(icon: Icons.bar_chart_outlined, label: 'آمار و پیشرفت',
                  sub: 'نمودار جلسات و عملکرد',
                  onTap: () => _go(context, const ReportsScreen())),
              _DrawerItem(icon: Icons.calendar_month_outlined, label: 'گزارش ماهانه',
                  sub: 'خلاصه ماه جاری',
                  onTap: () => _go(context, const ReportsScreen())),
            ]),

            _DrawerSection(title: 'مالی', children: [
              _DrawerItem(icon: Icons.account_balance_wallet_outlined, label: 'وضعیت مالی',
                  sub: 'بدهی و پرداخت‌ها',
                  onTap: () => _go(context, const FinanceScreen())),
              _DrawerItem(icon: Icons.insights_outlined, label: 'گزارش مالی هوشمند',
                  sub: 'محاسبه ماهانه و تسویه',
                  onTap: () => _go(context, const FinanceScreen())),
            ]),

            _DrawerSection(title: 'تنظیمات', children: [
              _DrawerItem(icon: Icons.notifications_outlined, label: 'تنظیمات نوتیفیکیشن',
                  sub: 'یادآوری جلسات',
                  onTap: () => _go(context, const SettingsScreen())),
              _DrawerItem(icon: Icons.backup_outlined, label: 'پشتیبان‌گیری',
                  sub: 'ذخیره و بازیابی اطلاعات',
                  onTap: () => _go(context, const BackupScreen())),
            ]),

            _DrawerSection(title: 'حساب کاربری', children: [
              _DrawerItem(icon: Icons.sports_outlined, label: 'مربی',
                  sub: 'اطلاعات و تماس',
                  onTap: () => _go(context, const ProfileScreen())),
              _DrawerItem(icon: Icons.help_outline, label: 'راهنمای برنامه',
                  onTap: () => _go(context, const GuideScreen())),
            ]),

            const Divider(height: 24),

            _DrawerItem(icon: Icons.info_outline, label: 'درباره سازنده',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) _showAbout(context);
                  });
                }),
          ]),
        ),
      ]),
    );
  }

  void _showAbout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('درباره سازنده', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ED3B7), Color(0xFF0D6E8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.sports_tennis, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          const Text('دستیار تنیس',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark)),
          const Text('نسخه ۱.۰.۰',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          const Text('طراح', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('اشکان مردان‌پور',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            text: '0918•••3897',
            color: AppColors.accent,
            onTap: () => _launch('tel:09182777765'),
          ),
          const SizedBox(height: 8),
          _ContactRow(
            icon: Icons.camera_alt_outlined,
            text: 'Ashkan.Mardanpour',
            color: const Color(0xFFE91E8C),
            onTap: () async {
              final handle = 'Ashkan.Mardanpour';
              final appUrl = Uri.parse('instagram://user?username=$handle');
              final webUrl = Uri.parse('https://www.instagram.com/$handle');
              if (await canLaunchUrl(appUrl)) {
                await launchUrl(appUrl);
              } else {
                await launchUrl(webUrl, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.text,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      // long press = copy, tap = open
      onTap();
    },
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کپی شد'), duration: Duration(seconds: 1)));
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 8),
        Icon(Icons.open_in_new, size: 13, color: color.withAlpha(150)),
      ]),
    ),
  );
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DrawerSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.primary, letterSpacing: 0.5)),
    ),
    ...children,
  ]);
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label,
      required this.onTap, this.sub});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: AppColors.primary),
    ),
    title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    subtitle: sub != null
        ? Text(sub!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
    onTap: onTap,
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}
