import 'package:flutter/material.dart';
import '../../core/utils/jalali_helper.dart';

class MonthNavigator extends StatefulWidget {
  const MonthNavigator({super.key});

  @override
  State<MonthNavigator> createState() => _MonthNavigatorState();
}

class _MonthNavigatorState extends State<MonthNavigator> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final current = JalaliHelper.currentJalaliYearMonth;
    _year = current['year']!;
    _month = current['month']!;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = JalaliHelper.today;
    final isCurrentMonth = _year == today.year && _month == today.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'ماه بعد',
          ),
          Expanded(
            child: GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () => setState(() {
                      _year = today.year;
                      _month = today.month;
                    }),
              child: Column(
                children: [
                  Text(
                    JalaliHelper.monthName(_month),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    JalaliHelper.toPersianDigits(_year.toString()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!isCurrentMonth)
                    Text(
                      'بازگشت به امروز',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'ماه قبل',
          ),
        ],
      ),
    );
  }
}
