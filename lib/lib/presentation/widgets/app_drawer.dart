import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../screens/guide/guide_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/package/package_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🎾', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('دستیار تنیس',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            const Text('منوی اصلی',
                style: TextStyle(fontSize: 12, color: Colors.white60)),
          ]),
        ),

        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [

            // دوره تمرینی
            _DrawerSection(title: 'تمرین', children: [
              _DrawerItem(icon: Icons.sports_tennis_outlined, label: 'دوره تمرینی',
                  sub: 'وضعیت و پیشرفت دوره',
                  onTap: () => _go(context, const PackageScreen())),
              _DrawerItem(icon: Icons.event_note_outlined, label: 'جلسات',
                  sub: 'مشاهده و ویرایش جلسات',
                  onTap: () => _go(context, const SessionsScreen())),
            ]),

            // مالی
            _DrawerSection(title: 'مالی', children: [
              _DrawerItem(icon: Icons.account_balance_wallet_outlined, label: 'وضعیت مالی',
                  sub: 'بدهی · پرداخت‌ها',
                  onTap: () => _go(context, const FinanceScreen())),
              _DrawerItem(icon: Icons.shopping_bag_outlined, label: 'هزینه‌های جانبی',
                  sub: 'توپ · راکت · اورگریپ',
                  onTap: () => _go(context, const FinanceScreen())),
            ]),

            // حساب کاربری
            _DrawerSection(title: 'حساب کاربری', children: [
              _DrawerItem(icon: Icons.person_outline, label: 'پروفایل من',
                  onTap: () => _go(context, const ProfileScreen())),
              _DrawerItem(icon: Icons.help_outline, label: 'راهنمای برنامه',
                  onTap: () => _go(context, const GuideScreen())),
            ]),

            const Divider(height: 24),

            // درباره سازنده
            _DrawerItem(
              icon: Icons.info_outline,
              label: 'درباره سازنده',
              onTap: () { Navigator.pop(context); _showAbout(context); },
            ),
          ]),
        ),
      ]),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('درباره سازنده'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎾', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('دستیار تنیس', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('اشکان مردان‌پور\nنسخه ۱.۰.۰',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DrawerSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.primary, letterSpacing: 0.5)),
      ),
      ...children,
    ],
  );
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
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
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
