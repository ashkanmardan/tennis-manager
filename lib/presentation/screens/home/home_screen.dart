import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/jalali_helper.dart';
import '../../../data/repositories/app_repository.dart';
import '../students/students_screen.dart';
import '../sessions/sessions_screen.dart';
import '../payments/payments_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    SessionsScreen(),
    StudentsScreen(),
    PaymentsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'جلسات',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'شاگردان',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'پرداخت‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'گزارش',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final now = JalaliHelper.today;
    final monthSessions = repo.getSessionsForJalaliMonth(now.year, now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎾 مدیریت تنیس'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => repo.loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    JalaliHelper.formatDateLong(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        repo.activeCoach != null
                            ? 'مربی: ${repo.activeCoach!.name}'
                            : 'مربی تعریف نشده',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats row
            Text(
              'ماه جاری — ${JalaliHelper.monthName(now.month)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.people,
                    label: 'شاگرد فعال',
                    value: JalaliHelper.toPersianDigits(
                        repo.activeStudents.length.toString()),
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.sports_tennis,
                    label: 'جلسه این ماه',
                    value: JalaliHelper.toPersianDigits(
                        monthSessions.length.toString()),
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.repeat,
                    label: 'جلسه جبرانی',
                    value: JalaliHelper.toPersianDigits(
                        monthSessions.where((s) => s.isMakeup).length.toString()),
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.cancel_outlined,
                    label: 'لغو شده',
                    value: JalaliHelper.toPersianDigits(
                        monthSessions.where((s) => s.coachCancelled).length.toString()),
                    color: const Color(0xFFC62828),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'دسترسی سریع',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.add_circle,
                  label: 'ثبت جلسه',
                  color: const Color(0xFF2E7D32),
                  onTap: () {
                    // Navigate to add session
                  },
                ),
                _QuickAction(
                  icon: Icons.person_add,
                  label: 'شاگرد جدید',
                  color: const Color(0xFF1565C0),
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.attach_money,
                  label: 'ثبت پرداخت',
                  color: const Color(0xFF558B2F),
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.sports,
                  label: 'هزینه توپ',
                  color: const Color(0xFFE65100),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent sessions
            if (repo.sessions.isNotEmpty) ...[
              Text(
                'آخرین جلسات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...repo.sessions.take(3).map((session) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: session.isMakeup
                            ? const Color(0xFFE65100)
                            : session.coachCancelled
                                ? const Color(0xFFC62828)
                                : const Color(0xFF2E7D32),
                        child: Icon(
                          session.isMakeup
                              ? Icons.repeat
                              : session.coachCancelled
                                  ? Icons.cancel
                                  : Icons.sports_tennis,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(JalaliHelper.formatDateLong(session.date)),
                      subtitle: Text(
                        session.isMakeup
                            ? 'جلسه جبرانی'
                            : session.coachCancelled
                                ? 'لغو شده توسط مربی'
                                : 'جلسه عادی',
                      ),
                      trailing: session.venue != null
                          ? Text(
                              session.venue!,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
