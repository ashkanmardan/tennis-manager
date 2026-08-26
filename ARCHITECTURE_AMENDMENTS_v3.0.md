# ARCHITECTURE AMENDMENTS — v3.0
## اصلاحات روی FINAL_DESIGN_v2.1
### این سند v2.1 را override می‌کند — فقط تغییرات اینجاست

---

# ═══ اصلاح C1 + C5 — Credit Balance ═══

## تغییر در جدول athletes

```sql
CREATE TABLE athletes (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT    NOT NULL,
  phone          TEXT,
  birth_date     TEXT,
  is_active      INTEGER NOT NULL DEFAULT 1,
  join_date      TEXT    NOT NULL,
  credit_balance INTEGER NOT NULL DEFAULT 0,  -- 🆕 اضافه شد
  -- موجودی مثبت: پیش‌پرداخت یا مازاد پرداخت
  -- موجودی منفی: نباید اتفاق بیفتد
  notes          TEXT,
  created_at     TEXT    NOT NULL
);
```

## منطق credit_balance

```dart
// هنگام ثبت پرداخت advance:
// 1. payment در payments ذخیره می‌شود (payment_for = 'advance')
// 2. athletes.credit_balance += amount

// هنگام ساخت monthly_fee_record جدید (createMonthlyRecord):
// 1. رکورد با amount_due = fee_amount ساخته می‌شود
// 2. اگر athlete.credit_balance > 0:
//    auto_apply = min(credit_balance, amount_due)
//    amount_paid += auto_apply
//    credit_balance -= auto_apply
//    ذخیره payment خودکار با description = 'اعمال پیش‌پرداخت'
//    وضعیت status به‌روزرسانی

// هنگام overpayment (session-based):
// اگر amount_paid > amount_due بعد از update:
//    excess = amount_paid - amount_due
//    amount_paid = amount_due
//    status = 'settled'
//    athletes.credit_balance += excess
```

---

# ═══ اصلاح C2 — Migration Fix ═══

## جایگزینی Step 1 در Migration

```dart
// ❌ اشتباه — اسکیمای جدول حفظ نمی‌شود:
// CREATE TABLE athletes AS SELECT ... FROM students;

// ✅ درست:
Future<void> _step1_createAthletes(Database db) async {
  // ساخت جدول با schema کامل
  await db.execute('''
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

  // انتقال داده‌ها از جدول قدیمی
  await db.execute('''
    INSERT INTO athletes (id, name, phone, birth_date, is_active,
                         join_date, credit_balance, notes, created_at)
    SELECT id, name, phone, NULL, is_active,
           created_at, 0, notes, created_at
    FROM students
  ''');
}
```

---

# ═══ اصلاح C3 — MonthlyFeeRecord Creation Trigger ═══

## قانون صریح

```
هنگامی که monthly_fee_record برای ورزشکار X در ماه Y ساخته می‌شود:
  اگر رکورد برای (athlete_id=X, year=Y, month=M) وجود ندارد → بساز
  ConflictAlgorithm.ignore جلوی duplicate را می‌گیرد

زمان‌بندی اجرا (سه trigger):
  Trigger 1: باز شدن اپ (loadAll در AppRepository)
    → برای هر ورزشکار فعال:
       از ماه join_date تا ماه جاری:
         اگر رکورد نبود → بساز
  Trigger 2: ثبت ورزشکار جدید
    → رکورد ماه جاری ساخته می‌شود
  Trigger 3: تغییر ماه در UI
    → رکورد ماه جدید برای همه ورزشکاران فعال ساخته می‌شود
```

```dart
// در MonthlyFeeRepository:
Future<void> ensureRecordsExist(int athleteId, String joinDate) async {
  final joinJalali = JalaliHelper.parseJalaliDate(joinDate);
  final today = JalaliHelper.today;

  int y = joinJalali.year;
  int m = joinJalali.month;

  while (y < today.year || (y == today.year && m <= today.month)) {
    await createMonthlyRecord(athleteId, y, m); // با ConflictAlgorithm.ignore
    m++;
    if (m > 12) { m = 1; y++; }
  }
}
```

---

# ═══ اصلاح C4 — Attendance Status ═══

## تغییر در جدول attendance

```sql
CREATE TABLE attendance (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id        INTEGER NOT NULL,
  athlete_id        INTEGER NOT NULL,
  -- ❌ حذف شد: present INTEGER
  -- ✅ جایگزین:
  status            TEXT    NOT NULL DEFAULT 'present',
  -- 'present'   : حاضر بود
  -- 'absent'    : غایب (ورزشکار نیامد)
  -- 'cancelled' : جلسه لغو شد (مربی نیامد)
  -- 'makeup'    : این حضور، جبرانی محسوب می‌شود
  makeup_debt_id    INTEGER,
  notes             TEXT,
  FOREIGN KEY (session_id)     REFERENCES sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (athlete_id)     REFERENCES athletes(id),
  FOREIGN KEY (makeup_debt_id) REFERENCES makeup_debts(id),
  UNIQUE(session_id, athlete_id)
);
```

## منطق خودکار

```dart
// هنگام ثبت جلسه با coach_cancelled = true:
//   برای هر ورزشکار فعال → attendance.status = 'cancelled'
//   هیچ تأثیری روی sessions_count ندارد

// هنگام ثبت جلسه جبرانی:
//   attendance.status = 'makeup' برای ورزشکاری که جبران می‌کند
//   هیچ تأثیری روی sessions_count ندارد

// debt_calculator فقط status = 'present' می‌شمرد:
SELECT COUNT(*) FROM attendance a
JOIN sessions s ON a.session_id = s.id
WHERE a.athlete_id = ?
  AND s.jalali_year = ? AND s.jalali_month = ?
  AND a.status = 'present'
  AND s.session_type = 'regular'
```

## تغییر در Athlete model

```dart
// در attendance.dart:
enum AttendanceStatus { present, absent, cancelled, makeup }

class Attendance {
  final AttendanceStatus status; // جایگزین bool present
  bool get isPresent => status == AttendanceStatus.present;
  bool get isMakeup  => status == AttendanceStatus.makeup;
}
```

---

# ═══ اصلاح C6 — Package Strategy ═══

## تصمیم: sqflite با Repository Abstraction

با توجه به اینکه فاز Web تاریخ مشخص ندارد:
- **فعلاً با `sqflite` ادامه می‌دهیم** (سریع‌تر، ساده‌تر، بدون codegen)
- **Repository pattern کاملاً abstract** → migration به `drift` فقط در Repository layer

```dart
// abstract_database.dart — abstraction layer
abstract class AppDatabase {
  Future<List<Map<String, dynamic>>> query(String table, {
    String? where, List<Object?>? whereArgs, String? orderBy
  });
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(String table, Map<String, dynamic> values, {
    String? where, List<Object?>? whereArgs
  });
  Future<int> delete(String table, {
    String? where, List<Object?>? whereArgs
  });
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]);
}

// SqfliteDatabase implements AppDatabase (فعلاً)
// DriftDatabase implements AppDatabase  (موقع Web migration)
```

**نکته Image برای Web:** `receipt_image_path` در Web کار نمی‌کند. فعلاً نادیده می‌گیریم. در Web migration تصاویر به base64 در DB ذخیره خواهند شد.

---

# ═══ اصلاح C7 — Backup Strategy ═══

## Backup JSON Schema

```json
{
  "version": 2,
  "app_version": "2.1.0",
  "created_at": "1403-03-15T17:00:00",
  "type": "lite",

  "coaches": [
    { "id": 1, "name": "علی احمدی", "phone": "...", "is_active": 1,
      "start_date": "2023-10-01", "end_date": null, "notes": null }
  ],

  "athletes": [
    { "id": 1, "name": "رضا محمدی", "phone": "...",
      "is_active": 1, "join_date": "1402-07-01",
      "credit_balance": 0, "notes": null }
  ],

  "athlete_fee_plans": [
    { "id": 1, "athlete_id": 1, "fee_type": "monthly",
      "fee_amount": 900000, "effective_from": "1402-07-01",
      "effective_to": null }
  ],

  "monthly_fee_records": [
    { "id": 1, "athlete_id": 1, "jalali_year": 1403,
      "jalali_month": 3, "fee_type": "monthly",
      "amount_due": 900000, "amount_paid": 700000,
      "sessions_count": 0, "status": "partial" }
  ],

  "sessions": [ ... ],
  "attendance": [ ... ],
  "payments": [ ... ],
  "expenses": [ ... ],
  "makeup_debts": [ ... ],

  "images": null
  // در backup_full:
  // "images": { "payment_1": "base64...", "expense_3": "base64..." }
}
```

## Restore Strategy

```
Restore = Replace All (نه Merge)

فرآیند:
1. نمایش dialog تأییدیه:
   "⚠ تمام اطلاعات فعلی حذف می‌شود و با بکاپ جایگزین می‌شود. ادامه می‌دهید؟"
2. بعد از تأیید:
   - DROP TABLE + CREATE TABLE (یا DELETE FROM همه جداول)
   - INSERT داده‌های بکاپ
   - Reload اپ

Backup Validation:
   - بررسی version compatibility
   - اگر backup.version > db.version → reject با پیام خطا
   - اگر backup.version < db.version → run migrations روی داده بکاپ
```

---

# ═══ اصلاح C8 — Tuition Payment Validation ═══

## Validation در Repository (نه Schema)

```dart
// در PaymentRepository:
Future<void> addPayment(Payment payment) async {
  // Validation
  if (payment.paymentFor == 'tuition' &&
      payment.monthlyFeeRecordId == null) {
    throw ArgumentError(
      'پرداخت شهریه باید به یک ماه خاص وابسته باشد.'
    );
  }

  // Insert
  final id = await _db.insert('payments', payment.toMap());

  // Update monthly record
  if (payment.monthlyFeeRecordId != null) {
    await DebtCalculator.applyPayment(
      payment.monthlyFeeRecordId!,
      payment.amount,
      _db
    );
  } else if (payment.paymentFor == 'advance') {
    // Update credit_balance
    await _db.rawUpdate(
      'UPDATE athletes SET credit_balance = credit_balance + ? WHERE id = ?',
      [payment.amount, payment.athleteId]
    );
  }
}
```

---

# ═══ خلاصه تغییرات Schema ═══

## جداول تغییر یافته نسبت به v2.1

| جدول | تغییر |
|------|-------|
| `athletes` | + `credit_balance INTEGER DEFAULT 0` |
| `attendance` | حذف `present INTEGER`، اضافه `status TEXT` |
| حذف `is_makeup_attendance` از attendance | به `status = 'makeup'` تبدیل شد |

## جداول بدون تغییر از v2.1
- `coaches` ✓
- `athlete_fee_plans` ✓
- `monthly_fee_records` ✓
- `sessions` ✓
- `makeup_debts` ✓
- `payments` ✓
- `expenses` ✓
- `iranian_holidays` ✓

---

# ═══ Architecture Approved For Production ═══

```
FINAL_DESIGN_v2.1 + ARCHITECTURE_AMENDMENTS_v3.0
= Production-Ready Architecture

سند مرجع نهایی پیاده‌سازی:
  1. FINAL_DESIGN_v2.1.md  ← پایه
  2. ARCHITECTURE_AMENDMENTS_v3.0.md  ← override
```
