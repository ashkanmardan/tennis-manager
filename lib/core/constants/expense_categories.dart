class ExpenseCategory {
  final String key;
  final String label;
  final String emoji;

  const ExpenseCategory({required this.key, required this.label, required this.emoji});

  static const List<ExpenseCategory> all = [
    ExpenseCategory(key: 'ball',       label: 'توپ',       emoji: '🎾'),
    ExpenseCategory(key: 'racket',     label: 'راکت',      emoji: '🏏'),
    ExpenseCategory(key: 'stringing',  label: 'زه‌کشی',    emoji: '🔗'),
    ExpenseCategory(key: 'grip',       label: 'گریپ',      emoji: '✊'),
    ExpenseCategory(key: 'shoe',       label: 'کفش',       emoji: '👟'),
    ExpenseCategory(key: 'clothing',   label: 'لباس',      emoji: '👕'),
    ExpenseCategory(key: 'tournament', label: 'مسابقات',   emoji: '🏆'),
    ExpenseCategory(key: 'transport',  label: 'رفت‌وآمد',  emoji: '🚗'),
    ExpenseCategory(key: 'other',      label: 'سایر',      emoji: '📋'),
  ];

  static ExpenseCategory fromKey(String key) =>
      all.firstWhere((c) => c.key == key, orElse: () => all.last);
}
