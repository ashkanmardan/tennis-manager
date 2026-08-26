import 'package:sqflite/sqflite.dart';
import '../../../core/constants/holiday_data.dart';
import '../../../core/utils/jalali_helper.dart';

class MigrationV1ToV2 {
  static Future<void> run(Database db) async {
    await db.transaction((txn) async {
      // ── Step 1: athletes از students ───────────────────────────────────────
      await txn.execute('''
        CREATE TABLE athletes (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          name           TEXT    NOT NULL,
          phone          TEXT,
          birth_date     TEXT,
          is_active      INTEGER NOT NULL DEFAULT 1,
          join_date      TEXT    NOT NULL,
          credit_balance INTEGER NOT NULL DEFAULT 0,
          notes          TEXT,
          created_at     TEXT    NOT NULL
        )
      ''');
      await txn.execute('''
        INSERT INTO athletes (id, name, phone, birth_date, is_active,
                              join_date, credit_balance, notes, created_at)
        SELECT id, name, phone, NULL, is_active,
               created_at, 0, notes, created_at
        FROM students
      ''');

      // ── Step 2: athlete_fee_plans از students.fee_type/fee_amount ──────────
      await txn.execute('''
        CREATE TABLE athlete_fee_plans (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          athlete_id      INTEGER NOT NULL,
          fee_type        TEXT    NOT NULL,
          fee_amount      INTEGER NOT NULL,
          effective_from  TEXT    NOT NULL,
          effective_to    TEXT,
          notes           TEXT,
          created_at      TEXT    NOT NULL,
          FOREIGN KEY (athlete_id) REFERENCES athletes(id)
        )
      ''');
      // شهریه فعلی به‌عنوان اولین plan از تاریخ ورود ورزشکار
      await txn.execute('''
        INSERT INTO athlete_fee_plans
          (athlete_id, fee_type, fee_amount, effective_from, created_at)
        SELECT id, fee_type, fee_amount, created_at, created_at
        FROM students
        WHERE fee_type IS NOT NULL AND fee_amount IS NOT NULL
      ''');

      // ── Step 3: monthly_fee_records ────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE monthly_fee_records (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          athlete_id      INTEGER NOT NULL,
          jalali_year     INTEGER NOT NULL,
          jalali_month    INTEGER NOT NULL,
          fee_type        TEXT    NOT NULL,
          amount_due      INTEGER NOT NULL,
          amount_paid     INTEGER NOT NULL DEFAULT 0,
          sessions_count  INTEGER NOT NULL DEFAULT 0,
          status          TEXT    NOT NULL DEFAULT 'pending',
          notes           TEXT,
          created_at      TEXT    NOT NULL,
          FOREIGN KEY (athlete_id) REFERENCES athletes(id),
          UNIQUE(athlete_id, jalali_year, jalali_month)
        )
      ''');
      // رکوردهای ماهانه در AppRepository.loadAll() ساخته می‌شوند

      // ── Step 4: اضافه کردن ستون‌های جدید به sessions ──────────────────────
      await txn.execute('ALTER TABLE sessions ADD COLUMN jalali_year INTEGER');
      await txn.execute('ALTER TABLE sessions ADD COLUMN jalali_month INTEGER');
      await txn.execute('ALTER TABLE sessions ADD COLUMN time TEXT');
      await txn.execute('ALTER TABLE sessions ADD COLUMN duration_minutes INTEGER DEFAULT 60');
      // پر کردن jalali_year/month از date
      final sessions = await txn.query('sessions', columns: ['id', 'date']);
      for (final s in sessions) {
        final date = s['date'] as String?;
        if (date == null) continue;
        final jm = JalaliHelper.jalaliYearMonth(date);
        await txn.update('sessions',
          {'jalali_year': jm['year'], 'jalali_month': jm['month']},
          where: 'id = ?', whereArgs: [s['id']]);
      }

      // ── Step 5: اضافه کردن ستون‌های جدید به payments ──────────────────────
      await txn.execute('ALTER TABLE payments ADD COLUMN jalali_year INTEGER');
      await txn.execute('ALTER TABLE payments ADD COLUMN jalali_month INTEGER');
      await txn.execute('ALTER TABLE payments ADD COLUMN monthly_fee_record_id INTEGER');
      // پر کردن jalali
      final payments = await txn.query('payments', columns: ['id', 'date']);
      for (final p in payments) {
        final date = p['date'] as String?;
        if (date == null) continue;
        final jm = JalaliHelper.jalaliYearMonth(date);
        await txn.update('payments',
          {'jalali_year': jm['year'], 'jalali_month': jm['month']},
          where: 'id = ?', whereArgs: [p['id']]);
      }

      // ── Step 6: attendance — اضافه کردن status، حفظ present ───────────────
      await txn.execute("ALTER TABLE attendance ADD COLUMN status TEXT DEFAULT 'present'");
      await txn.execute('ALTER TABLE attendance ADD COLUMN makeup_debt_id INTEGER');
      // تبدیل present → status
      await txn.execute('''
        UPDATE attendance SET status =
          CASE WHEN present = 1 THEN 'present' ELSE 'absent' END
      ''');
      // اگر is_makeup_for = 1 بود → status = 'makeup'
      await txn.execute('''
        UPDATE attendance SET status = 'makeup'
        WHERE isMakeupFor = 1 OR is_makeup_for = 1
      ''');

      // ── Step 7: makeup_debts ───────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE makeup_debts (
          id                 INTEGER PRIMARY KEY AUTOINCREMENT,
          athlete_id         INTEGER NOT NULL,
          session_id         INTEGER NOT NULL,
          reason             TEXT    NOT NULL,
          is_settled         INTEGER NOT NULL DEFAULT 0,
          settled_session_id INTEGER,
          settled_at         TEXT,
          notes              TEXT,
          created_at         TEXT    NOT NULL,
          FOREIGN KEY (athlete_id)         REFERENCES athletes(id),
          FOREIGN KEY (session_id)         REFERENCES sessions(id),
          FOREIGN KEY (settled_session_id) REFERENCES sessions(id)
        )
      ''');

      // ── Step 8: expenses از ball_costs ─────────────────────────────────────
      await txn.execute('''
        CREATE TABLE expenses (
          id                 INTEGER PRIMARY KEY AUTOINCREMENT,
          date               TEXT    NOT NULL,
          jalali_year        INTEGER NOT NULL DEFAULT 0,
          jalali_month       INTEGER NOT NULL DEFAULT 0,
          category           TEXT    NOT NULL DEFAULT 'ball',
          amount             INTEGER NOT NULL,
          athlete_id         INTEGER,
          session_id         INTEGER,
          description        TEXT,
          receipt_image_path TEXT,
          created_at         TEXT    NOT NULL,
          FOREIGN KEY (athlete_id) REFERENCES athletes(id),
          FOREIGN KEY (session_id) REFERENCES sessions(id)
        )
      ''');
      // انتقال ball_costs → expenses
      final tableCheck = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='ball_costs'");
      if (tableCheck.isNotEmpty) {
        final ballCosts = await txn.query('ball_costs');
        for (final bc in ballCosts) {
          final date = (bc['date'] as String?) ?? DateTime.now().toIso8601String().substring(0, 10);
          final jm   = JalaliHelper.jalaliYearMonth(date);
          await txn.insert('expenses', {
            'date':        date,
            'jalali_year': jm['year'],
            'jalali_month': jm['month'],
            'category':    'ball',
            'amount':      bc['total_cost'] ?? 0,
            'session_id':  bc['session_id'],
            'description': bc['notes'],
            'created_at':  bc['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // ── Step 9: iranian_holidays ───────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE iranian_holidays (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          jalali_month  INTEGER NOT NULL,
          jalali_day    INTEGER NOT NULL,
          title         TEXT    NOT NULL,
          is_recurring  INTEGER NOT NULL DEFAULT 1,
          jalali_year   INTEGER
        )
      ''');
      for (final h in HolidayData.recurringHolidays) {
        await txn.insert('iranian_holidays', {
          'jalali_month': h['month'],
          'jalali_day':   h['day'],
          'title':        h['title'],
          'is_recurring': 1,
          'jalali_year':  null,
        });
      }

      // ── Step 10: indexes ───────────────────────────────────────────────────
      final indexes = [
        'CREATE INDEX IF NOT EXISTS idx_ath_active    ON athletes(is_active)',
        'CREATE INDEX IF NOT EXISTS idx_ses_jalali    ON sessions(jalali_year, jalali_month)',
        'CREATE INDEX IF NOT EXISTS idx_ses_coach     ON sessions(coach_id)',
        'CREATE INDEX IF NOT EXISTS idx_att_athlete   ON attendance(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_mfr_athlete   ON monthly_fee_records(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_mfr_jalali    ON monthly_fee_records(jalali_year, jalali_month)',
        'CREATE INDEX IF NOT EXISTS idx_mfr_status    ON monthly_fee_records(status)',
        'CREATE INDEX IF NOT EXISTS idx_mfr_ath_month ON monthly_fee_records(athlete_id, jalali_year, jalali_month)',
        'CREATE INDEX IF NOT EXISTS idx_pay_athlete   ON payments(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_pay_jalali    ON payments(jalali_year, jalali_month)',
        'CREATE INDEX IF NOT EXISTS idx_pay_record    ON payments(monthly_fee_record_id)',
        'CREATE INDEX IF NOT EXISTS idx_exp_jalali    ON expenses(jalali_year, jalali_month)',
        'CREATE INDEX IF NOT EXISTS idx_exp_athlete   ON expenses(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_afp_athlete   ON athlete_fee_plans(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_mkup_athlete  ON makeup_debts(athlete_id)',
        'CREATE INDEX IF NOT EXISTS idx_mkup_settled  ON makeup_debts(is_settled)',
      ];
      for (final sql in indexes) await txn.execute(sql);
    });
  }
}
