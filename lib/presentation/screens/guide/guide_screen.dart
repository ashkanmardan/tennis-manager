import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('راهنمای برنامه', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: const [
          _GuideCard(
            icon: Icons.home_outlined,
            title: 'صفحه اصلی',
            color: AppColors.primary,
            steps: [
              'تاریخ امروز و احوال‌پرسی بالای صفحه نمایش داده می‌شود',
              'نوار آمار: جلسه ماه، پیشرفت پکیج و بدهی',
              'کارت «امروز کلاس داری» فقط وقتی جلسه امروز دارید دیده می‌شود',
              'دکمه بله: جلسه را برگزار شده ثبت می‌کند',
              'دکمه خیر: علت لغو را می‌پرسد و ثبت می‌کند',
              'کارت‌های خلاصه: آخرین جلسه، پکیج، جبرانی، مالی',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.calendar_month_outlined,
            title: 'جلسات',
            color: Color(0xFF0D8A6E),
            steps: [
              'لیست جلسات ماه جاری را می‌بینید',
              'با فلش‌های بالا ماه قبل/بعد را ببینید',
              'روی هر جلسه بزنید تا جزئیات و تغییر وضعیت ببینید',
              'جلسه جدید برای ثبت جلسه آینده',
              'جلسه‌های تعطیل رسمی با رنگ صورتی مشخص می‌شوند',
              'جلسه جبرانی با برچسب جداگانه نمایش داده می‌شود',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.inventory_2_outlined,
            title: 'پکیج تمرینی',
            color: AppColors.primaryDark,
            steps: [
              'پکیج = تعداد جلسات خریداری شده',
              'نوار پیشرفت نشان می‌دهد چند جلسه مانده',
              'مبلغ کل، پرداخت شده و مانده نمایش داده می‌شود',
              'پکیج جدید برای شروع دوره تمرینی جدید',
              'پکیج فعال با حاشیه آبی مشخص است',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'مالی',
            color: AppColors.makeup,
            steps: [
              'خلاصه مالی پکیج فعال در بالا',
              'اگر بدهی دارید با رنگ قرمز نشان می‌دهد',
              'تاریخچه کامل پرداخت‌ها',
              'ثبت پرداخت هر بار که پول می‌دهید',
              'می‌توانید پرداخت‌ها را حذف کنید',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.person_outline,
            title: 'پروفایل',
            color: Color(0xFF1A4A5A),
            steps: [
              'اطلاعات شما: نام، تلفن، روزهای تمرین',
              'اطلاعات مربی: نام، تلفن، اینستاگرام، شماره کارت',
              'روی تلفن مربی بزنید تا مستقیم زنگ بزنید',
              'روی اینستاگرام بزنید تا اپ باز شود',
              'روی شماره کارت بزنید تا کپی شود',
              'دکمه ویرایش بالا برای تغییر اطلاعات',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.rule_folder_outlined,
            title: 'وضعیت جلسات',
            color: Color(0xFF5C35BE),
            steps: [
              'برگزار شد: جلسه طبیعی انجام شده',
              'لغو توسط مربی: جلسه جبرانی ایجاد می‌شود',
              'لغو توسط شما: از پکیج کسر می‌شود',
              'لغو آب‌وهوایی: جلسه جبرانی ایجاد می‌شود',
              'تعطیل رسمی: ثبت می‌شود بدون جبرانی',
              'تغییر زمان: تاریخ جدید ثبت می‌شود',
            ],
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.info_outline,
            title: 'نکات کلی',
            color: Color(0xFF6D4C41),
            steps: [
              'همه اطلاعات روی گوشی ذخیره می‌شه، نیاز به اینترنت نیست',
              'برای بکاپ از منو → پشتیبان‌گیری استفاده کنید',
              'تاریخ‌ها شمسی نمایش داده می‌شوند',
              'اعداد به فارسی نمایش داده می‌شوند',
              'تعطیلات رسمی ایران خودکار شناسایی می‌شوند',
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> steps;
  const _GuideCard({required this.icon, required this.title,
      required this.color, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(right: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: color.withAlpha(12),
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14), topLeft: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
        // steps
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.map((s) => _Step(text: s, color: color)).toList()),
        ),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String text;
  final Color color;
  const _Step({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 6, height: 6, margin: const EdgeInsets.only(top: 6, left: 10),
        decoration: BoxDecoration(color: color.withAlpha(150), shape: BoxShape.circle),
      ),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333))),
      ),
    ]),
  );
}
