import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_manager/core/utils/number_formatter.dart';

void main() {
  test('formats payment amounts with thousands separators', () {
    expect(NumberFormatter.format(1500000), '1,500,000');
    expect(NumberFormatter.formatCurrency(1500000), '1,500,000 تومان');
  });

  test('parses displayed payment amounts', () {
    expect(NumberFormatter.parse('1,500,000'), 1500000);
    expect(NumberFormatter.parse(' 1,500,000 '), 1500000);
    expect(NumberFormatter.parse('invalid'), 0);
  });
}
