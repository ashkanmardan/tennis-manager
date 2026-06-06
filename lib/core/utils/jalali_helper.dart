import 'package:shamsi_date/shamsi_date.dart';

class JalaliHelper {
  static final List<String> _monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد',
    'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر',
    'دی', 'بهمن', 'اسفند',
  ];

  static final List<String> _weekDays = [
    'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه',
    'چهارشنبه', 'پنجشنبه', 'جمعه',
  ];

  /// Convert DateTime to Jalali
  static Jalali toJalali(DateTime date) => Jalali.fromDateTime(date);

  /// Get today in Jalali
  static Jalali get today => Jalali.now();

  /// Format: ۱۴۰۳/۰۶/۱۵
  static String formatDate(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.year.toString())}/${toPersianDigits(j.month.toString().padLeft(2, '0'))}/${toPersianDigits(j.day.toString().padLeft(2, '0'))}';
  }

  /// Format: ۱۵ شهریور ۱۴۰۳
  static String formatDateLong(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.day.toString())} ${_monthNames[j.month - 1]} ${toPersianDigits(j.year.toString())}';
  }

  /// Format: شهریور ۱۴۰۳
  static String formatMonthYear(DateTime date) {
    final j = toJalali(date);
    return '${_monthNames[j.month - 1]} ${toPersianDigits(j.year.toString())}';
  }

  /// Get month name
  static String monthName(int month) => _monthNames[month - 1];

  /// Get Jalali month name from DateTime
  static String getMonthName(DateTime date) {
    final j = toJalali(date);
    return _monthNames[j.month - 1];
  }

  /// Convert to Gregorian DateTime
  static DateTime toDateTime(int jYear, int jMonth, int jDay) {
    return Jalali(jYear, jMonth, jDay).toDateTime();
  }

  /// Convert Arabic/Persian digits to Latin
  static String toLatinDigits(String input) {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result
          .replaceAll(persianDigits[i], i.toString())
          .replaceAll(arabicDigits[i], i.toString());
    }
    return result;
  }

  /// Convert Latin digits to Persian
  static String toPersianDigits(String input) {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(i.toString(), persianDigits[i]);
    }
    return result;
  }

  /// Format amount with thousand separators
  static String formatAmount(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return toPersianDigits(str);
  }

  /// Get current Jalali year and month
  static Map<String, int> get currentJalaliYearMonth {
    final j = Jalali.now();
    return {'year': j.year, 'month': j.month};
  }

  /// Check if two DateTimes are in same Jalali month
  static bool isSameJalaliMonth(DateTime d1, DateTime d2) {
    final j1 = toJalali(d1);
    final j2 = toJalali(d2);
    return j1.year == j2.year && j1.month == j2.month;
  }
}
