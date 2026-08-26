import 'package:sqflite/sqflite.dart';
import 'jalali_helper.dart';

/// محاسبه و اعمال بدهی — تمام منطق مالی اینجاست
class DebtCalculator {

  // ── کل بدهی یک ورزشکار (همه ماه‌ها) ─────────────────────────────────────
  static Future<int> totalDebt(int athleteId, Database db) async {
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_due - amount_paid), 0) AS debt
      FROM monthly_fee_records
      WHERE athlete_id = ? AND status NOT IN ('waived', 'settled')
    ''', [athleteId]);
    return (r.first['debt'] as num?)?.toInt() ?? 0;
  }

  // ── بدهی یک ماه خاص ───────────────────────────────────────────────────────
  static Future<int> monthDebt(int athleteId, int year, int month, Database db) async {
    final r = await db.query('monthly_fee_records',
      where: 'athlete_id = ? AND jalali_year = ? AND jalali_month = ?',
      whereArgs: [athleteId, year, month]);
    if (r.isEmpty) return 0;
    final rec = r.first;
    final due  = (rec['amount_due']  as int? ) ?? 0;
    final paid = (rec['amount_paid'] as int? ) ?? 0;
    return (due - paid).clamp(0, double.maxFinite.toInt());
  }

  // ── اعمال پرداخت به یک رکورد ماهانه ─────────────────────────────────────
  /// [amount] : مبلغ پرداختی
  /// بازمی‌گرداند: مبلغ مازاد (برای کردیت به athlete)
  static Future<int> applyPaymentToRecord(
      int recordId, int amount, Database db) async {
    final r = await db.query('monthly_fee_records',
        where: 'id = ?', whereArgs: [recordId]);
    if (r.isEmpty) return amount; // رکورد یافت نشد → همه مازاد

    final rec      = r.first;
    final due      = (rec['amount_due']  as int? ) ?? 0;
    final paid     = (rec['amount_paid'] as int? ) ?? 0;
    final remaining = due - paid;

    int applied = amount;
    int surplus = 0;

    if (amount > remaining) {
      applied = remaining;
      surplus = amount - remaining;
    }

    final newPaid  = paid + applied;
    final newStatus = _computeStatus(due, newPaid);

    await db.update('monthly_fee_records',
      {'amount_paid': newPaid, 'status': newStatus},
      where: 'id = ?', whereArgs: [recordId]);

    return surplus; // مازاد → به credit_balance ورزشکار
  }

  // ── اعمال credit به قدیمی‌ترین رکورد بدهکار ─────────────────────────────
  static Future<void> applyCredit(
      int athleteId, int creditAmount, Database db) async {
    if (creditAmount <= 0) return;
    final records = await db.query('monthly_fee_records',
      where: 'athlete_id = ? AND status IN (\'pending\', \'partial\')',
      whereArgs: [athleteId],
      orderBy: 'jalali_year ASC, jalali_month ASC');

    int remaining = creditAmount;
    for (final rec in records) {
      if (remaining <= 0) break;
      final id   = rec['id'] as int;
      final due  = (rec['amount_due']  as int?) ?? 0;
      final paid = (rec['amount_paid'] as int?) ?? 0;
      final gap  = due - paid;
      if (gap <= 0) continue;

      final apply   = remaining < gap ? remaining : gap;
      final newPaid = paid + apply;
      remaining    -= apply;

      await db.update('monthly_fee_records',
        {'amount_paid': newPaid, 'status': _computeStatus(due, newPaid)},
        where: 'id = ?', whereArgs: [id]);
    }

    // مازاد کردیت را به credit_balance ورزشکار برگردان
    if (remaining > 0) {
      await db.rawUpdate(
        'UPDATE athletes SET credit_balance = credit_balance + ? WHERE id = ?',
        [remaining, athleteId]);
    }
  }

  // ── به‌روزرسانی رکورد جلسه‌ای بعد از تغییر حضور ────────────────────────
  static Future<void> updateSessionFeeRecord(
      int athleteId, int year, int month, Database db) async {
    // نرخ جلسه‌ای فعلی
    final plan = await db.rawQuery('''
      SELECT fee_amount FROM athlete_fee_plans
      WHERE athlete_id = ? AND effective_to IS NULL
      ORDER BY effective_from DESC LIMIT 1
    ''', [athleteId]);
    if (plan.isEmpty) return;

    final rate = (plan.first['fee_amount'] as int?) ?? 0;

    // تعداد جلسات regular که ورزشکار present بوده
    final count = await db.rawQuery('''
      SELECT COUNT(*) AS cnt
      FROM attendance a
      JOIN sessions s ON a.session_id = s.id
      WHERE a.athlete_id = ?
        AND s.jalali_year = ?
        AND s.jalali_month = ?
        AND a.status = 'present'
        AND s.session_type = 'regular'
        AND s.coach_cancelled = 0
    ''', [athleteId, year, month]);

    final sessionCount  = (count.first['cnt'] as int?) ?? 0;
    final newAmountDue  = sessionCount * rate;

    // رکورد موجود را بخوان
    final existing = await db.query('monthly_fee_records',
      where: 'athlete_id = ? AND jalali_year = ? AND jalali_month = ?',
      whereArgs: [athleteId, year, month]);

    if (existing.isEmpty) return;
    final rec       = existing.first;
    final amountPaid = (rec['amount_paid'] as int?) ?? 0;

    int finalDue   = newAmountDue;
    int finalPaid  = amountPaid;
    int surplus    = 0;

    // overpayment: مازاد به credit_balance
    if (amountPaid > newAmountDue) {
      surplus   = amountPaid - newAmountDue;
      finalPaid = newAmountDue;
      finalDue  = newAmountDue;
    }

    await db.update('monthly_fee_records', {
      'sessions_count': sessionCount,
      'amount_due':     finalDue,
      'amount_paid':    finalPaid,
      'status':         _computeStatus(finalDue, finalPaid),
    }, where: 'id = ?', whereArgs: [rec['id']]);

    // اضافه کردن مازاد به credit_balance
    if (surplus > 0) {
      await db.rawUpdate(
        'UPDATE athletes SET credit_balance = credit_balance + ? WHERE id = ?',
        [surplus, athleteId]);
    }
  }

  // ── ساخت رکورد ماهانه ─────────────────────────────────────────────────────
  /// اگر رکورد وجود داشت نادیده می‌گیرد (UNIQUE constraint)
  static Future<void> createMonthlyRecord(
      int athleteId, int year, int month, Database db) async {
    final plan = await db.rawQuery('''
      SELECT fee_type, fee_amount FROM athlete_fee_plans
      WHERE athlete_id = ? AND effective_to IS NULL
      ORDER BY effective_from DESC LIMIT 1
    ''', [athleteId]);
    if (plan.isEmpty) return;

    final feeType   = plan.first['fee_type']   as String;
    final feeAmount = (plan.first['fee_amount'] as int?) ?? 0;
    final now       = DateTime.now().toIso8601String();

    await db.insert('monthly_fee_records', {
      'athlete_id':    athleteId,
      'jalali_year':   year,
      'jalali_month':  month,
      'fee_type':      feeType,
      'amount_due':    feeType == 'monthly' ? feeAmount : 0,
      'amount_paid':   0,
      'sessions_count': 0,
      'status':        feeType == 'monthly' ? 'pending' : 'settled',
      'created_at':    now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // اعمال credit_balance موجود ورزشکار به این ماه
    final ath = await db.query('athletes',
        columns: ['credit_balance'], where: 'id = ?', whereArgs: [athleteId]);
    if (ath.isNotEmpty) {
      final credit = (ath.first['credit_balance'] as int?) ?? 0;
      if (credit > 0 && feeType == 'monthly') {
        // صفر کردن credit و اعمال به رکورد
        await db.update('athletes', {'credit_balance': 0},
            where: 'id = ?', whereArgs: [athleteId]);
        final surplus = await applyPaymentToRecord(
            (await db.rawQuery(
              'SELECT id FROM monthly_fee_records WHERE athlete_id=? AND jalali_year=? AND jalali_month=?',
              [athleteId, year, month])
            ).first['id'] as int,
            credit, db);
        if (surplus > 0) {
          await db.rawUpdate(
            'UPDATE athletes SET credit_balance = credit_balance + ? WHERE id = ?',
            [surplus, athleteId]);
        }
      }
    }
  }

  // ── ساخت رکوردهای تمام ماه‌های از join_date تا الان ──────────────────────
  static Future<void> ensureRecordsExist(
      int athleteId, String joinDate, Database db) async {
    // تبدیل join_date (جلالی) به میلادی برای مقایسه
    final parts = joinDate.split('-');
    int jy = int.parse(parts[0]);
    int jm = int.parse(parts[1]);

    final today   = JalaliHelper.today;
    final endYear  = today.year;
    final endMonth = today.month;

    while (jy < endYear || (jy == endYear && jm <= endMonth)) {
      await createMonthlyRecord(athleteId, jy, jm, db);
      jm++;
      if (jm > 12) { jm = 1; jy++; }
    }
  }

  // ── helper ─────────────────────────────────────────────────────────────────
  static String _computeStatus(int due, int paid) {
    if (due == 0)       return 'settled';
    if (paid >= due)    return 'settled';
    if (paid > 0)       return 'partial';
    return 'pending';
  }
}
