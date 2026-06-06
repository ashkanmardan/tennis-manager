class NumberFormatter {
  /// Format number with thousand separator: 1,500,000
  static String format(num amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// Format as currency with تومان suffix
  static String formatCurrency(num amount) => '${format(amount)} تومان';

  /// Parse formatted number back to int
  static int parse(String formatted) {
    return int.tryParse(
          formatted.replaceAll(',', '').replaceAll(' ', ''),
        ) ??
        0;
  }
}
