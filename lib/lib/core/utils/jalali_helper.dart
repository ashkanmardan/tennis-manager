import 'package:shamsi_date/shamsi_date.dart';

class JalaliHelper {
  static const List<String> monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر',     'مرداد',    'شهریور',
    'مهر',     'آبان',     'آذر',
    'دی',      'بهمن',     'اسفند',
  ];

  static const List<String> weekDays = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه',
    'چهارشنبه', 'پنجشنبه', 'جمعه',
  ];

  static Jalali toJalali(DateTime date) => Jalali.fromDateTime(date);
  static Jalali get today => Jalali.now();

  /// Parse Jalali ISO string "1403-01-15" → Jalali
  static Jalali parseJalaliDate(String jalaliIso) {
    final parts = jalaliIso.split('-');
    return Jalali(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Format Jalali ISO from year/month/day → "1403-01-15"
  static String toJalaliIso(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Today as Jalali ISO string
  static String get todayIso {
    final j = today;
    return toJalaliIso(j.year, j.month, j.day);
  }

  /// Format: ۱۴۰۳/۰۳/۱۵
  static String formatDate(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.year.toString())}/${toPersianDigits(j.month.toString().padLeft(2, '0'))}/${toPersianDigits(j.day.toString().padLeft(2, '0'))}';
  }

  /// Format Jalali ISO string for display
  static String formatJalaliIso(String jalaliIso) {
    final j = parseJalaliDate(jalaliIso);
    return '${toPersianDigits(j.year.toString())}/${toPersianDigits(j.month.toString().padLeft(2, '0'))}/${toPersianDigits(j.day.toString().padLeft(2, '0'))}';
  }

  /// Format: ۱۵ خرداد ۱۴۰۳
  static String formatDateLong(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.day.toString())} ${monthNames[j.month - 1]} ${toPersianDigits(j.year.toString())}';
  }

  /// Format Jalali ISO to long
  static String formatJalaliIsoLong(String jalaliIso) {
    final j = parseJalaliDate(jalaliIso);
    return '${toPersianDigits(j.day.toString())} ${monthNames[j.month - 1]} ${toPersianDigits(j.year.toString())}';
  }

  /// Format short: ۱۵ خرداد (no year)
  static String formatDateShort(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.day.toString())} ${monthNames[j.month - 1]}';
  }

  /// Format: خرداد ۱۴۰۳
  static String formatMonthYear(int year, int month) =>
      '${monthNames[month - 1]} ${toPersianDigits(year.toString())}';

  static String formatMonthYearFromDate(DateTime date) {
    final j = toJalali(date);
    return formatMonthYear(j.year, j.month);
  }

  static String monthName(int month) => monthNames[month - 1];

  /// Convert to Gregorian DateTime
  static DateTime toDateTime(int jYear, int jMonth, int jDay) =>
      Jalali(jYear, jMonth, jDay).toDateTime();

  /// Compute jalali year/month from a Gregorian date string "YYYY-MM-DD"
  static Map<String, int> jalaliYearMonth(String gregorianDate) {
    final dt = DateTime.parse(gregorianDate);
    final j  = toJalali(dt);
    return {'year': j.year, 'month': j.month};
  }

  /// Days in a Jalali month
  static int daysInMonth(int year, int month) =>
      Jalali(year, month, 1).monthLength;

  /// Previous month
  static Map<String, int> previousMonth(int year, int month) {
    if (month == 1) return {'year': year - 1, 'month': 12};
    return {'year': year, 'month': month - 1};
  }

  /// Next month
  static Map<String, int> nextMonth(int year, int month) {
    if (month == 12) return {'year': year + 1, 'month': 1};
    return {'year': year, 'month': month + 1};
  }

  /// Compare two jalali ISO strings
  static bool isBeforeOrEqual(String a, String b) => a.compareTo(b) <= 0;

  static String toLatinDigits(String input) {
    const p = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    const a = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String r = input;
    for (int i = 0; i < 10; i++) {
      r = r.replaceAll(p[i], '$i').replaceAll(a[i], '$i');
    }
    return r;
  }

  static String toPersianDigits(String input) {
    const p = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    String r = input;
    for (int i = 0; i < 10; i++) r = r.replaceAll('$i', p[i]);
    return r;
  }

  static String formatAmount(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return toPersianDigits(str);
  }

  static Map<String, int> get currentJalaliYearMonth {
    final j = Jalali.now();
    return {'year': j.year, 'month': j.month};
  }

  static bool isSameJalaliMonth(DateTime d1, DateTime d2) {
    final j1 = toJalali(d1);
    final j2 = toJalali(d2);
    return j1.year == j2.year && j1.month == j2.month;
  }
}
