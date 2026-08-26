# FINAL DESIGN DOCUMENT — v2.1
## Tennis Manager App
### Database Design + ER Diagram + Migration Plan + Screen Map
#### تغییرات نسبت به v2.0: Athlete-Centric + MonthlyFeeRecord

---

# ═══════════════════════════════════════
# تحلیل تغییرات v2.0 → v2.1
# ═══════════════════════════════════════

## چرا Athlete-Centric؟

در v2.0 سیستم هنوز Session-centric بود:
- بدهی از «تعداد جلسات × شهریه» محاسبه می‌شد
- شاگرد فقط در attendance ظاهر می‌شد
- گزارش مالی ماه‌محور بود، نه ورزشکار‌محور

در v2.1 **ورزشکار موجودیت اصلی** است:
- هر ورزشکار یک پرونده مستقل دارد
- هر ماه یک رکورد مالی صریح برای هر ورزشکار ساخته می‌شود (MonthlyFeeRecord)
- گزارش از زاویه ورزشکار شروع می‌شود: «کجا ایستاده؟»
- هم‌کلاسی‌ها فقط در لیست حضور‌وغیاب جلسه دیده می‌شوند — داده جانبی

## چرا MonthlyFeeRecord؟

مشکل رویکرد قبلی (محاسبه پویا از fee_history):
- هر بار بدهی باید از ابتدا محاسبه شود
- اگر شهریه وسط سال تغییر کند، محاسبه ماه‌های گذشته پیچیده می‌شود
- برای شهریه جلسه‌ای، باید تعداد جلسات حاضر × نرخ حساب شود
- ورود نیمه‌ماه، معافیت یک ماه، تخفیف — قابل ذخیره نیست

راه‌حل `monthly_fee_records`:
- یک رکورد صریح per-athlete per-month
- `amount_due` هنگام ساخت قفل می‌شود (از نرخ آن لحظه کپی)
- `amount_paid` مجموع پرداخت‌های مرتبط است
- بدهی = `amount_due - amount_paid` — بدون محاسبه پیچیده
- قابل اصلاح دستی توسط مربی (تخفیف، معافیت)

---

# ═══════════════════════════════════════
# بخش ۱ — Database Final Design (v2.1)
# ═══════════════════════════════════════

## اصول طراحی

- **Athlete-centric:** ورزشکار موجودیت اصلی سیستم است
- **MonthlyFeeRecord:** بدهی هر ماه صریح ثبت می‌شود، نه محاسبه پویا
- **Fee Plans:** نرخ شهریه با تاریخچه کامل نگه داشته می‌شود
- **Coach Independence:** هر مربی پرونده مستقل دارد
- **Jalali-native:** سال و ماه جلالی در جداول ذخیره می‌شود
- **Offline-first:** تمام داده‌ها در SQLite محلی

---

## جدول ۱ — coaches (مربیان)

```sql
CREATE TABLE coaches (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  phone       TEXT,
  is_active   INTEGER NOT NULL DEFAULT 1,   -- فقط یکی active است
  start_date  TEXT    NOT NULL,             -- YYYY-MM-DD میلادی
  end_date    TEXT,                         -- null = هنوز فعال
  notes       TEXT,
  created_at  TEXT    NOT NULL
);
```

**قوانین:**
- هر بار که مربی جدید set active شود، مربی قبلی `end_date` می‌گیرد
- `is_active = 1` فقط برای یک رکورد در هر زمان
- حذف ممنوع — فقط غیرفعال (تاریخچه حفظ)

---

## جدول ۲ — athletes (ورزشکاران) — تغییر نام از students

```sql
CREATE TABLE athletes (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  phone       TEXT,
  birth_date  TEXT,                         -- جلالی ISO، اختیاری
  is_active   INTEGER NOT NULL DEFAULT 1,
  join_date   TEXT    NOT NULL,             -- جلالی ISO: 1403-01-01
  notes       TEXT,
  created_at  TEXT    NOT NULL
);
```

**تغییر از v2.0:**
- نام جدول: `students` → `athletes`
- محتوا یکسان — `fee_type` و `fee_amount` در `athlete_fee_plans` هستند

---

## جدول ۳ — athlete_fee_plans (نرخ شهریه) — تغییر نام از fee_history

```sql
CREATE TABLE athlete_fee_plans (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id      INTEGER NOT NULL,
  fee_type        TEXT    NOT NULL,   -- 'monthly' | 'session'
  fee_amount      INTEGER NOT NULL,   -- مبلغ به تومان
  effective_from  TEXT    NOT NULL,   -- جلالی ISO: 1403-01-01
  effective_to    TEXT,               -- null = هنوز معتبر
  notes           TEXT,
  created_at      TEXT    NOT NULL,
  FOREIGN KEY (athlete_id) REFERENCES athletes(id)
);
```

**نقش این جدول:**
- فقط نرخ را نگه می‌دارد — نه بدهی را
- هنگام ساخت `monthly_fee_records`، از این جدول نرخ خوانده می‌شود
- تغییر شهریه: رکورد فعلی `effective_to` می‌گیرد، رکورد جدید اضافه می‌شود

---

## جدول ۴ — monthly_fee_records (رکورد مالی ماهانه) 🆕 اصلی‌ترین جدول مالی

```sql
CREATE TABLE monthly_fee_records (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id      INTEGER NOT NULL,
  jalali_year     INTEGER NOT NULL,
  jalali_month    INTEGER NOT NULL,
  fee_type        TEXT    NOT NULL,   -- 'monthly' | 'session' (از plan کپی شد)
  amount_due      INTEGER NOT NULL,   -- مبلغ باید پرداخت شود (قفل‌شده)
  amount_paid     INTEGER NOT NULL DEFAULT 0,  -- مجموع پرداخت‌های این ماه
  sessions_count  INTEGER NOT NULL DEFAULT 0,  -- تعداد جلسات حاضر (برای session-based)
  status          TEXT    NOT NULL DEFAULT 'pending',
  -- pending: هنوز پرداخت نشده
  -- partial: بخشی پرداخت شده
  -- settled: کاملاً تسویه
  -- waived: معاف شد (توسط مربی)
  notes           TEXT,
  created_at      TEXT    NOT NULL,
  FOREIGN KEY (athlete_id) REFERENCES athletes(id),
  UNIQUE(athlete_id, jalali_year, jalali_month)
);
```

**چرخه زندگی یک رکورد:**

```
ورزشکار ماهانه:
  [شروع ماه] → ساخت رکورد با amount_due = fee_amount فعلی، status = pending
  [پرداخت]   → amount_paid افزایش، status → partial یا settled
  [معافیت]   → status = waived، amount_due = 0

ورزشکار جلسه‌ای:
  [ثبت حضور] → sessions_count++، amount_due = sessions_count × fee_amount (به‌روزرسانی)
  [پرداخت]   → amount_paid افزایش، status به‌روزرسانی

محاسبه بدهی کل ورزشکار:
  SELECT SUM(amount_due - amount_paid)
  FROM monthly_fee_records
  WHERE athlete_id = ? AND status != 'waived'
```

**قوانین:**
- جلسه جبرانی (makeup): به `sessions_count` اضافه **نمی‌شود**
- جلسه‌ای که ورزشکار غایب است: به `sessions_count` اضافه نمی‌شود
  (اما در ماهانه: `amount_due` تغییر نمی‌کند — طبق PRD)
- مربی می‌تواند `amount_due` را دستی ویرایش کند (تخفیف، ورود نیمه‌ماه)

---

## جدول ۵ — sessions (جلسات)

```sql
CREATE TABLE sessions (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  date                TEXT    NOT NULL,             -- YYYY-MM-DD میلادی
  jalali_year         INTEGER NOT NULL,             -- برای query سریع
  jalali_month        INTEGER NOT NULL,             -- برای query سریع
  time                TEXT,                         -- HH:MM اختیاری
  duration_minutes    INTEGER NOT NULL DEFAULT 60,
  session_type        TEXT    NOT NULL DEFAULT 'regular', -- regular | makeup
  coach_id            INTEGER,
  venue               TEXT,
  coach_cancelled     INTEGER NOT NULL DEFAULT 0,
  requires_makeup     INTEGER NOT NULL DEFAULT 0,
  original_session_id INTEGER,                      -- makeup → جلسه اصلی
  notes               TEXT,
  created_at          TEXT    NOT NULL,
  FOREIGN KEY (coach_id)            REFERENCES coaches(id),
  FOREIGN KEY (original_session_id) REFERENCES sessions(id)
);
```

---

## جدول ۶ — attendance (حضور و غیاب)

```sql
CREATE TABLE attendance (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id           INTEGER NOT NULL,
  athlete_id           INTEGER NOT NULL,
  present              INTEGER NOT NULL DEFAULT 1,
  is_makeup_attendance INTEGER NOT NULL DEFAULT 0,  -- این حضور، جبرانی است
  makeup_debt_id       INTEGER,
  notes                TEXT,
  FOREIGN KEY (session_id)     REFERENCES sessions(id)  ON DELETE CASCADE,
  FOREIGN KEY (athlete_id)     REFERENCES athletes(id),
  FOREIGN KEY (makeup_debt_id) REFERENCES makeup_debts(id),
  UNIQUE(session_id, athlete_id)
);
```

---

## جدول ۷ — makeup_debts (بدهی جبرانی)

```sql
CREATE TABLE makeup_debts (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id         INTEGER NOT NULL,
  session_id         INTEGER NOT NULL,   -- جلسه‌ای که بدهی ایجاد کرد
  reason             TEXT    NOT NULL,   -- 'athlete_absent' | 'coach_cancelled'
  is_settled         INTEGER NOT NULL DEFAULT 0,
  settled_session_id INTEGER,            -- جلسه جبرانی که تسویه کرد
  settled_at         TEXT,
  notes              TEXT,
  created_at         TEXT    NOT NULL,
  FOREIGN KEY (athlete_id)         REFERENCES athletes(id),
  FOREIGN KEY (session_id)         REFERENCES sessions(id),
  FOREIGN KEY (settled_session_id) REFERENCES sessions(id)
);
```

**قوانین:**
- مربی جلسه لغو کند + `requires_makeup = 1` → یک بدهی جبرانی برای هر ورزشکار حاضر
- ورزشکار غیبت کند (بنا به تشخیص مربی) → مربی می‌تواند بدهی جبرانی ثبت کند
- جلسه جبرانی: **هیچ هزینه مالی ندارد** (sessions_count تغییر نمی‌کند)

---

## جدول ۸ — payments (پرداخت‌ها)

```sql
CREATE TABLE payments (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id            INTEGER NOT NULL,
  amount                INTEGER NOT NULL,
  date                  TEXT    NOT NULL,
  jalali_year           INTEGER NOT NULL,
  jalali_month          INTEGER NOT NULL,
  monthly_fee_record_id INTEGER,          -- ربط به کدام ماه (اختیاری)
  payment_for           TEXT    NOT NULL DEFAULT 'tuition',
  -- tuition: شهریه | expense: هزینه جانبی | advance: پیش‌پرداخت
  expense_id            INTEGER,
  description           TEXT,
  receipt_image_path    TEXT,
  receipt_note          TEXT,
  created_at            TEXT    NOT NULL,
  FOREIGN KEY (athlete_id)            REFERENCES athletes(id),
  FOREIGN KEY (monthly_fee_record_id) REFERENCES monthly_fee_records(id),
  FOREIGN KEY (expense_id)            REFERENCES expenses(id)
);
```

**تغییر از v2.0:**
- اضافه شد: `monthly_fee_record_id` — پرداخت به یک ماه خاص وابسته می‌شود
- اضافه شد نوع `advance` — پیش‌پرداخت بدون ماه مشخص

**منطق اعمال پرداخت:**
```
اگر monthly_fee_record_id مشخص باشد:
  → amount_paid در آن رکورد افزایش می‌یابد
  → status رکورد به‌روز می‌شود

اگر monthly_fee_record_id مشخص نباشد (advance):
  → پرداخت در موجودی مثبت ورزشکار نگه داشته می‌شود
  → هنگام ساخت رکورد ماه بعد، از موجودی کسر می‌شود
```

---

## جدول ۹ — expenses (هزینه‌های جانبی)

```sql
CREATE TABLE expenses (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  date               TEXT    NOT NULL,
  jalali_year        INTEGER NOT NULL,
  jalali_month       INTEGER NOT NULL,
  category           TEXT    NOT NULL,
  -- ball | racket | stringing | grip | shoe |
  -- clothing | tournament | transport | other
  amount             INTEGER NOT NULL,
  athlete_id         INTEGER,            -- null = هزینه عمومی کلاس
  session_id         INTEGER,            -- null = مستقل از جلسه
  description        TEXT,
  receipt_image_path TEXT,
  created_at         TEXT    NOT NULL,
  FOREIGN KEY (athlete_id) REFERENCES athletes(id),
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

---

## جدول ۱۰ — iranian_holidays (تعطیلات رسمی)

```sql
CREATE TABLE iranian_holidays (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  jalali_month  INTEGER NOT NULL,
  jalali_day    INTEGER NOT NULL,
  title         TEXT    NOT NULL,
  is_recurring  INTEGER NOT NULL DEFAULT 1,
  jalali_year   INTEGER               -- null = هر سال
);
```

---

## ایندکس‌های پرفورمنس

```sql
-- athletes
CREATE INDEX idx_ath_active     ON athletes(is_active);

-- sessions
CREATE INDEX idx_ses_jalali     ON sessions(jalali_year, jalali_month);
CREATE INDEX idx_ses_coach      ON sessions(coach_id);
CREATE INDEX idx_ses_date       ON sessions(date);

-- attendance
CREATE INDEX idx_att_session    ON attendance(session_id);
CREATE INDEX idx_att_athlete    ON attendance(athlete_id);

-- monthly_fee_records (مهم‌ترین — بیشترین query)
CREATE INDEX idx_mfr_athlete    ON monthly_fee_records(athlete_id);
CREATE INDEX idx_mfr_jalali     ON monthly_fee_records(jalali_year, jalali_month);
CREATE INDEX idx_mfr_status     ON monthly_fee_records(status);
CREATE INDEX idx_mfr_ath_month  ON monthly_fee_records(athlete_id, jalali_year, jalali_month);

-- payments
CREATE INDEX idx_pay_athlete    ON payments(athlete_id);
CREATE INDEX idx_pay_jalali     ON payments(jalali_year, jalali_month);
CREATE INDEX idx_pay_record     ON payments(monthly_fee_record_id);

-- expenses
CREATE INDEX idx_exp_jalali     ON expenses(jalali_year, jalali_month);
CREATE INDEX idx_exp_athlete    ON expenses(athlete_id);

-- athlete_fee_plans
CREATE INDEX idx_afp_athlete    ON athlete_fee_plans(athlete_id);

-- makeup_debts
CREATE INDEX idx_mkup_athlete   ON makeup_debts(athlete_id);
CREATE INDEX idx_mkup_settled   ON makeup_debts(is_settled);
```

---

# ═══════════════════════════════════════
# بخش ۲ — ER Diagram (v2.1)
# ═══════════════════════════════════════

```
┌──────────────┐        ┌─────────────────┐
│   coaches    │        │ iranian_holidays │
│──────────────│        │─────────────────│
│ id           │        │ jalali_month    │
│ name         │        │ jalali_day      │
│ is_active    │        │ title           │
│ start_date   │        └─────────────────┘
│ end_date     │
└──────┬───────┘
       │ 1:N (coach_id)
       ▼
┌──────────────┐
│   sessions   │◄──────────────────────────────────┐
│──────────────│                                   │
│ id           │ 1:N (session_id)                  │
│ date         ├──────────────┐                    │
│ jalali_year  │              │                    │
│ jalali_month │              ▼                    │
│ time         │   ┌──────────────────┐            │
│ session_type │   │    attendance    │            │
│ coach_id(FK) │   │──────────────────│            │
│ venue        │   │ session_id  (FK) │            │
│ cancelled    │   │ athlete_id  (FK)─┼──┐         │
│ req_makeup   │   │ present          │  │         │
│ original_id  │   │ is_makeup        │  │         │
└──────────────┘   │ makeup_debt_id   │  │         │
                   └──────────────────┘  │         │
                                         │         │
┌────────────────────────────────────────┘         │
│                                                  │
▼                                                  │
┌──────────────┐   1:N    ┌───────────────────┐   │
│   athletes   ├──────────►  athlete_fee_plans │   │
│──────────────│          │───────────────────│   │
│ id           │          │ athlete_id    (FK) │   │
│ name         │          │ fee_type           │   │
│ phone        │          │ fee_amount         │   │
│ is_active    │          │ effective_from      │   │
│ join_date    │          │ effective_to        │   │
└──────┬───────┘          └───────────────────┘   │
       │                                           │
       │ 1:N              ┌───────────────────┐   │
       ├──────────────────► monthly_fee_records│   │
       │                  │───────────────────│   │
       │                  │ athlete_id    (FK) │   │
       │                  │ jalali_year        │   │
       │                  │ jalali_month       │   │
       │                  │ fee_type           │   │
       │                  │ amount_due         │   │
       │                  │ amount_paid        │   │
       │                  │ sessions_count     │   │
       │                  │ status             │   │
       │                  └────────┬──────────┘   │
       │                           │ 1:N           │
       │                           ▼               │
       │ 1:N              ┌────────────────┐       │
       ├──────────────────►    payments    │       │
       │                  │────────────────│       │
       │                  │ athlete_id (FK)│       │
       │                  │ amount         │       │
       │                  │ record_id  (FK)│       │
       │                  │ expense_id (FK)│       │
       │                  │ receipt        │       │
       │                  └────────────────┘       │
       │                                           │
       │ 1:N              ┌────────────────┐       │
       ├──────────────────►  makeup_debts  ├───────┘
       │                  │────────────────│ (settled_session_id)
       │                  │ athlete_id (FK)│
       │                  │ session_id (FK)│
       │                  │ reason         │
       │                  │ is_settled     │
       │                  └────────────────┘
       │
       │ 1:N              ┌────────────────┐
       └──────────────────►    expenses    │
                          │────────────────│
                          │ athlete_id (FK)│
                          │ category       │
                          │ amount         │
                          └────────────────┘
```

---

# ═══════════════════════════════════════
# بخش ۳ — Migration Plan (v1 → v2.1)
# ═══════════════════════════════════════

## روش Migration

- DB version: 1 → 2
- `onUpgrade(db, oldVersion, newVersion)` در DatabaseHelper
- در صورت fresh install: `onCreate` مستقیم schema v2.1 را می‌سازد

## مراحل کامل (onUpgrade از v1 به v2)

```dart
// migration_v1_to_v2.dart
Future<void> migrateV1ToV2(Database db) async {
```

**مرحله ۱ — ساخت جدول athletes از روی students**
```sql
-- SQLite نمی‌تواند rename table در قدیمی — جدول جدید می‌سازیم
CREATE TABLE athletes AS SELECT
  id, name, phone, NULL AS birth_date,
  is_active, created_at AS join_date, notes, created_at
FROM students;
```

**مرحله ۲ — ساخت athlete_fee_plans**
```sql
CREATE TABLE athlete_fee_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id INTEGER NOT NULL,
  fee_type TEXT NOT NULL,
  fee_amount INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  notes TEXT,
  created_at TEXT NOT NULL
);

-- انتقال شهریه از students
INSERT INTO athlete_fee_plans
  (athlete_id, fee_type, fee_amount, effective_from, created_at)
SELECT id, fee_type, fee_amount, '1402-07-01', created_at
FROM students;
```

**مرحله ۳ — ساخت monthly_fee_records**
```sql
CREATE TABLE monthly_fee_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id INTEGER NOT NULL,
  jalali_year INTEGER NOT NULL,
  jalali_month INTEGER NOT NULL,
  fee_type TEXT NOT NULL,
  amount_due INTEGER NOT NULL,
  amount_paid INTEGER NOT NULL DEFAULT 0,
  sessions_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TEXT NOT NULL,
  UNIQUE(athlete_id, jalali_year, jalali_month)
);
-- داده‌های اولیه در Dart ساخته می‌شوند (ماه جاری به بعد)
```

**مرحله ۴ — اضافه کردن ستون‌های جدید به sessions**
```sql
ALTER TABLE sessions ADD COLUMN jalali_year INTEGER;
ALTER TABLE sessions ADD COLUMN jalali_month INTEGER;
ALTER TABLE sessions ADD COLUMN time TEXT;
ALTER TABLE sessions ADD COLUMN duration_minutes INTEGER DEFAULT 60;
-- پر کردن jalali در Dart: loop + shamsi_date
```

**مرحله ۵ — اضافه کردن ستون‌های جدید به payments**
```sql
ALTER TABLE payments ADD COLUMN jalali_year INTEGER;
ALTER TABLE payments ADD COLUMN jalali_month INTEGER;
ALTER TABLE payments ADD COLUMN monthly_fee_record_id INTEGER;
-- student_id → athlete_id: چون نمی‌توان ستون rename کرد،
-- در مدل Dart athlete_id از student_id خوانده می‌شود (alias)
```

**مرحله ۶ — اصلاح attendance**
```sql
ALTER TABLE attendance ADD COLUMN is_makeup_attendance INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN makeup_debt_id INTEGER;
-- student_id در attendance همچنان وجود دارد — alias در Dart
```

**مرحله ۷ — ساخت makeup_debts**
```sql
CREATE TABLE makeup_debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  athlete_id INTEGER NOT NULL,
  session_id INTEGER NOT NULL,
  reason TEXT NOT NULL,
  is_settled INTEGER NOT NULL DEFAULT 0,
  settled_session_id INTEGER,
  settled_at TEXT,
  notes TEXT,
  created_at TEXT NOT NULL
);
```

**مرحله ۸ — ساخت expenses و انتقال ball_costs**
```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  jalali_year INTEGER NOT NULL DEFAULT 0,
  jalali_month INTEGER NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'ball',
  amount INTEGER NOT NULL,
  athlete_id INTEGER,
  session_id INTEGER,
  description TEXT,
  receipt_image_path TEXT,
  created_at TEXT NOT NULL
);

INSERT INTO expenses (date, amount, session_id, created_at)
SELECT date, total_cost, session_id, created_at FROM ball_costs;
-- jalali_year/month در Dart پر می‌شوند
```

**مرحله ۹ — ایجاد iranian_holidays و داده‌های اولیه**
```sql
CREATE TABLE iranian_holidays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  jalali_month INTEGER NOT NULL,
  jalali_day INTEGER NOT NULL,
  title TEXT NOT NULL,
  is_recurring INTEGER NOT NULL DEFAULT 1,
  jalali_year INTEGER
);

INSERT INTO iranian_holidays (jalali_month, jalali_day, title) VALUES
  (1, 1, 'نوروز'), (1, 2, 'نوروز'), (1, 3, 'نوروز'),
  (1, 4, 'نوروز'), (1, 13, 'سیزده به در'),
  (3, 14, 'رحلت امام خمینی'), (3, 15, 'قیام پانزده خرداد'),
  (11, 22, 'پیروزی انقلاب اسلامی'),
  (12, 29, 'ملی شدن صنعت نفت');
```

**مرحله ۱۰ — ساخت ایندکس‌ها**
```sql
CREATE INDEX ... (تمام ایندکس‌های بخش ۱)
```

**مرحله ۱۱ — پاکسازی (اختیاری)**
```sql
-- DROP TABLE students; -- فعلاً نگه می‌داریم برای ایمنی
-- DROP TABLE ball_costs;
```

---

# ═══════════════════════════════════════
# بخش ۴ — Screen Map نهایی (v2.1)
# ═══════════════════════════════════════

## ساختار Navigation

```
App Start
│
└── MainScreen (Bottom Nav — 5 Tab)
    ├── Tab 0: 🏠 خانه (Dashboard)
    ├── Tab 1: 📅 جلسات (Sessions)
    ├── Tab 2: 🏃 ورزشکاران (Athletes)
    ├── Tab 3: 💰 مالی (Finances)
    └── Tab 4: 📊 گزارش (Reports)
                    └── ⚙ Settings (AppBar icon)
```

---

## Tab 0 — Dashboard (خانه)

```
┌─────────────────────────────────────┐
│  🎾 تنیس               [⚙ تنظیمات] │
├─────────────────────────────────────┤
│  📅 ۱۵ خرداد ۱۴۰۳ — شنبه          │
│  مربی فعال: علی احمدی              │
├─────────────────────────────────────┤
│  خرداد ۱۴۰۳                        │
│  ┌──────────┐  ┌──────────┐         │
│  │ورزشکار  │  │ جلسه    │         │
│  │فعال: ۵  │  │این ماه:۸│         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │بدهکاران │  │جبرانی   │         │
│  │۲ نفر    │  │بدهکار: ۱│         │
│  └──────────┘  └──────────┘         │
├─────────────────────────────────────┤
│  دسترسی سریع                        │
│  [+ جلسه] [+ ورزشکار] [+ پرداخت]  │
│  [+ هزینه] [حضور امروز]             │
├─────────────────────────────────────┤
│  ⚠ بدهکاران این ماه                 │
│  • رضا محمدی ——— ۲۰۰،۰۰۰ تومان    │
│  • علی رضایی ——— ۱،۶۰۰،۰۰۰ تومان  │
├─────────────────────────────────────┤
│  آخرین جلسات                        │
│  🟢 ۱۵ خرداد — ۱۷:۰۰ — حاضر: ۴/۵  │
│  🟠 ۱۳ خرداد — جبرانی              │
└─────────────────────────────────────┘
```

---

## Tab 1 — Sessions (جلسات)

```
┌─────────────────────────────────────┐
│  جلسات     [< خرداد ۱۴۰۳ >]  [+]  │
├─────────────────────────────────────┤
│  کل:۸ | عادی:۵ | جبرانی:۲ | لغو:۱  │
├─────────────────────────────────────┤
│  ۱  ۲  ۳  ۴  ●  ۶  ۷              │
│  ۸  ۹  ●  ۱۱ ۱۲ ●  ●             │
│  ۱۵ ۱۶ ۱۷ ۱۸ ●  ۲۰ ۲۱            │
├─────────────────────────────────────┤
│  🟢 ۱۵ خرداد — ۱۷:۰۰              │
│     زمین ۲ | ۶۰ دقیقه | حاضر: ۴/۵ │
│  🟠 ۱۳ خرداد — جبرانی            │
│     برای: ۵ فروردین | حاضر: ۱/۵  │
│  🔴 ۱۰ خرداد — لغو مربی           │
│     نیاز به جبران: ✓               │
└─────────────────────────────────────┘
```

### Session Detail
```
┌─────────────────────────────────────┐
│ ← ۱۵ خرداد ۱۴۰۳ — ۱۷:۰۰  [ویرایش]│
├─────────────────────────────────────┤
│  🟢 جلسه عادی | زمین ۲ | ۶۰ دقیقه  │
│  مربی: علی احمدی                    │
├─────────────────────────────────────┤
│  حضور ورزشکاران      [همه حاضر ✓]  │
│  • رضا محمدی          ✓ حاضر        │
│  • سارا کریمی          ✓ حاضر        │
│  • علی رضایی           ✗ غایب        │
│  • نگار صادقی          ✓ حاضر        │
├─────────────────────────────────────┤
│  [ذخیره حضور]   [+ هزینه این جلسه] │
└─────────────────────────────────────┘
```

### Add Session Sheet
```
┌─────────────────────────────────────┐
│  ثبت جلسه                       [×] │
├─────────────────────────────────────┤
│  تاریخ: [۱۵ خرداد ۱۴۰۳]  [📅]     │
│  ساعت شروع: [۱۷:۰۰]  (اختیاری)    │
│  مدت: [۶۰] دقیقه                   │
│  نوع جلسه: (●) عادی  ( ) جبرانی    │
│    └─ جبرانی برای: [انتخاب جلسه ▼] │
│  مکان: [________________]           │
│  ────────────────────────           │
│  [ ] لغو شده توسط مربی              │
│      [ ] نیاز به جلسه جبرانی دارد  │
│  ────────────────────────           │
│  یادداشت: [________________]        │
│                                     │
│          [ذخیره جلسه]              │
└─────────────────────────────────────┘
```

---

## Tab 2 — Athletes (ورزشکاران) — تغییر نام از Students

```
┌─────────────────────────────────────┐
│  ورزشکاران            [+ ورزشکار]  │
├─────────────────────────────────────┤
│  [🔍 جستجوی نام...]                │
├─────────────┬───────────────────────┤
│  فعال (۵)  │  غیرفعال (۲)          │
├─────────────┴───────────────────────┤
│  ┌─────────────────────────────────┐│
│  │[ر] رضا محمدی                   ││
│  │    ماهانه ۹۰۰،۰۰۰ | ⚠ بدهکار  ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │[س] سارا کریمی                  ││
│  │    جلسه‌ای ۵۰،۰۰۰ | ✓ تسویه   ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │[ن] نگار صادقی                  ││
│  │    ماهانه ۸۰۰،۰۰۰ | ✓ تسویه   ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Athlete Profile (پرونده ورزشکار) — جایگزین Student Detail
```
┌─────────────────────────────────────┐
│ ← رضا محمدی                  [ویرایش]│
├─────────────────────────────────────┤
│  ⚠ بدهکار: ۲۰۰،۰۰۰ تومان          │
│  [ ثبت پرداخت سریع ]               │
├───────┬──────┬───────┬──────────────┤
│اطلاعات│مالی  │حضور  │ جبرانی        │
├───────┴──────┴───────┴──────────────┤

--- Tab اطلاعات ---
│  نام: رضا محمدی                    │
│  تلفن: ۰۹۱۲۱۲۳۴۵۶۷               │
│  تاریخ شروع: ۱ مهر ۱۴۰۲           │
│  شهریه فعلی: ماهانه ۹۰۰،۰۰۰       │
│  [ تاریخچه شهریه → ]               │
│  یادداشت: ...                       │

--- Tab مالی ---
│  [ < خرداد ۱۴۰۳ > ]  [همه ماه‌ها] │
│  ──────────────────────             │
│  خرداد: باید ۹۰۰،۰۰۰  پرداخت ۷۰۰،۰۰۰  │
│  مانده: ۲۰۰،۰۰۰ ⚠  [پرداخت]      │
│  اردیبهشت: ✓ تسویه ۹۰۰،۰۰۰       │
│  فروردین: ✓ تسویه ۹۰۰،۰۰۰        │
│  ──────────────────────             │
│  کل بدهی: ۲۰۰،۰۰۰ تومان           │
│  آخرین پرداخت: ۱۵ خرداد           │
│  ──────────────────────             │
│  پرداخت‌ها:                         │
│  • ۱۵ خرداد — ۷۰۰،۰۰۰ [رسید 📎]  │
│  • ۱ اردیبهشت — ۹۰۰،۰۰۰           │

--- Tab حضور ---
│  کل جلسات: ۲۷  حاضر: ۲۴  غایب: ۳ │
│  درصد حضور: ۸۹٪                    │
│  ──────────────────────             │
│  • ۱۵ خرداد ✓  • ۱۳ خرداد ✓      │
│  • ۱۰ خرداد ✗ (لغو مربی)          │

--- Tab جبرانی ---
│  جلسات جبرانی بدهکار: ۱            │
│  • ۵ فروردین — لغو مربی            │
│    ⏳ در انتظار جبران               │
│  جلسات جبرانی تسویه‌شده: ۲         │
│  • ۱۲ دی ✓ — جبران شد ۲۰ دی      │
└─────────────────────────────────────┘
```

### Add Athlete Sheet
```
┌─────────────────────────────────────┐
│  ثبت ورزشکار جدید               [×] │
├─────────────────────────────────────┤
│  نام: [_______________________]     │
│  تلفن: [______________________]     │
│  تاریخ شروع: [۱ خرداد ۱۴۰۳] [📅]  │
│  ──────────────────────             │
│  نوع شهریه:                         │
│  (●) ماهانه  ( ) جلسه‌ای            │
│  مبلغ شهریه: [__________] تومان     │
│  ──────────────────────             │
│  یادداشت: [___________________]     │
│                                     │
│  [ ذخیره ورزشکار ]                 │
└─────────────────────────────────────┘
```

### Fee Plan History Screen
```
┌─────────────────────────────────────┐
│ ← تاریخچه شهریه — رضا محمدی        │
├─────────────────────────────────────┤
│  شهریه فعلی: ماهانه ۹۰۰،۰۰۰       │
│                      [ تغییر شهریه ]│
├─────────────────────────────────────┤
│  • ماهانه ۹۰۰،۰۰۰                  │
│    از ۱۴۰۳/۰۱ تا الان (فعال)       │
│  • ماهانه ۸۰۰،۰۰۰                  │
│    از ۱۴۰۲/۰۷ تا ۱۴۰۳/۰۱          │
└─────────────────────────────────────┘
```

---

## Tab 3 — Finances (مالی)

```
┌─────────────────────────────────────┐
│  مالی        [< خرداد ۱۴۰۳ >]      │
├─────────────────────────────────────┤
│  [پرداخت‌ها] [هزینه‌ها] [بدهکاران]  │
├─────────────────────────────────────┤

--- Tab: پرداخت‌ها ---
│  دریافتی خرداد: ۴،۵۰۰،۰۰۰ تومان   │
│  ────────────────────               │
│  • رضا محمدی — ۷۰۰،۰۰۰  ۱۵ خرداد │
│  • سارا کریمی — ۹۰۰،۰۰۰  ۱۲ خرداد│
│  • نگار صادقی — ۸۰۰،۰۰۰  ۵ خرداد  │
│                                     │
│  [ + ثبت پرداخت ]                  │

--- Tab: هزینه‌ها ---
│  هزینه خرداد: ۱،۲۰۰،۰۰۰ تومان     │
│  توپ ۸۰۰،۰۰۰  |  زه‌کشی ۴۰۰،۰۰۰  │
│  ────────────────────               │
│  🎾 ۱۵ خرداد — توپ — ۲۰۰،۰۰۰     │
│  🎾 ۱۲ خرداد — توپ — ۶۰۰،۰۰۰     │
│  🏏 ۱۰ خرداد — زه‌کشی — ۴۰۰،۰۰۰  │
│                                     │
│  [ + ثبت هزینه ]                   │

--- Tab: بدهکاران ---
│  کل بدهی: ۱،۸۰۰،۰۰۰ تومان         │
│  ────────────────────               │
│  رضا محمدی — خرداد — ۲۰۰،۰۰۰     │
│                        [ پرداخت ]  │
│  علی رضایی — ۳ ماه — ۱،۶۰۰،۰۰۰   │
│                        [ پرداخت ]  │
└─────────────────────────────────────┘
```

### Add Payment Sheet
```
┌─────────────────────────────────────┐
│  ثبت پرداخت                     [×] │
├─────────────────────────────────────┤
│  ورزشکار: [رضا محمدی ▼]            │
│  ────────────────────               │
│  پرداخت برای: (●) شهریه  ( ) هزینه │
│  ────────────────────               │
│  اعمال به ماه: [خرداد ۱۴۰۳ ▼]     │
│  (بدهی این ماه: ۲۰۰،۰۰۰ تومان)    │
│  ────────────────────               │
│  مبلغ: [__________] تومان          │
│  تاریخ: [۱۵ خرداد ۱۴۰۳] [📅]     │
│  توضیح: [________________]          │
│  رسید: [ 📸 عکس ] [ 📝 متن ]       │
│                                     │
│  [ ذخیره پرداخت ]                  │
└─────────────────────────────────────┘
```

### Add Expense Sheet
```
┌─────────────────────────────────────┐
│  ثبت هزینه                      [×] │
├─────────────────────────────────────┤
│  دسته‌بندی:                         │
│  [🎾توپ] [🏏راکت] [🔗زه‌کشی]       │
│  [✊گریپ] [👟کفش] [👕لباس]          │
│  [🏆مسابقات] [🚗رفت‌وآمد] [📋سایر] │
│  ────────────────────               │
│  مبلغ: [__________] تومان          │
│  تاریخ: [۱۵ خرداد ۱۴۰۳] [📅]     │
│  مربوط به ورزشکار: [ همه / انتخاب ]│
│  توضیح: [________________]          │
│  رسید: [ 📸 عکس ]                  │
│                                     │
│  [ ذخیره هزینه ]                   │
└─────────────────────────────────────┘
```

---

## Tab 4 — Reports (گزارش)

```
┌─────────────────────────────────────┐
│  گزارش         [< خرداد ۱۴۰۳ >]    │
├─────────────────────────────────────┤
│  [ماهانه] [مربی] [ورزشکار] [سالانه]│
├─────────────────────────────────────┤

--- Tab: ماهانه ---
│  📅 جلسات خرداد                     │
│  کل:۸ | عادی:۵ | جبرانی:۲ | لغو:۱  │
│                                     │
│  💰 مالی                            │
│  دریافتی:  ۴،۵۰۰،۰۰۰              │
│  هزینه‌ها: ۱،۲۰۰،۰۰۰              │
│  سود خالص: ۳،۳۰۰،۰۰۰              │
│                                     │
│  🏃 ورزشکاران                       │
│  فعال: ۵ | بدهکار: ۲ | تسویه: ۳   │
│                                     │
│  📊 وضعیت مالی هر ورزشکار          │
│  • رضا محمدی — ⚠ ۲۰۰،۰۰۰ بدهکار  │
│  • سارا کریمی — ✓ تسویه            │
│  • نگار صادقی — ✓ تسویه            │

--- Tab: مربی ---
│  [انتخاب مربی: احمدی ▼]            │
│  دوره: ۱۴۰۳/۰۱ — الان             │
│  جلسات: ۴۵ | جبرانی بدهکار: ۳     │
│  درآمد این دوره: ۲۲،۵۰۰،۰۰۰       │

--- Tab: ورزشکار ---
│  [انتخاب ورزشکار ▼]                │
│  رضا محمدی — از مهر ۱۴۰۲          │
│  حضور: ۸۹٪ | کل بدهی: ۲۰۰،۰۰۰    │
│  [نمودار پرداخت ۶ ماهه]            │

--- Tab: سالانه ---
│  سال ۱۴۰۳                          │
│  کل درآمد: ۲۷،۰۰۰،۰۰۰            │
│  کل هزینه: ۷،۲۰۰،۰۰۰              │
│  سود خالص: ۱۹،۸۰۰،۰۰۰            │
│  [نمودار ماهانه]                    │
└─────────────────────────────────────┘
```

---

## Settings Screen

```
┌─────────────────────────────────────┐
│ ← تنظیمات                           │
├─────────────────────────────────────┤
│  🧑‍🏫 مربی                            │
│  مربی فعال: علی احمدی  [ تغییر ]   │
│  تاریخچه مربیان →                   │
├─────────────────────────────────────┤
│  💾 پشتیبان‌گیری                     │
│  بکاپ Lite (بدون تصویر) →          │
│  بکاپ Full (با تصویر) →            │
│  بازگردانی بکاپ →                   │
├─────────────────────────────────────┤
│  📅 تعطیلات                         │
│  مدیریت تعطیلات مذهبی متغیر →     │
├─────────────────────────────────────┤
│  ℹ درباره اپ                        │
│  طراح: اشکان مردانپور              │
│  تلفن: ۰۹۱۸۸۵۹۳۸۹۷               │
│  نسخه ۲.۱.۰                        │
└─────────────────────────────────────┘
```

---

# ═══════════════════════════════════════
# بخش ۵ — معماری کد (v2.1)
# ═══════════════════════════════════════

## ساختار پوشه‌ها

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       -- dbVersion = 2
│   │   ├── expense_categories.dart
│   │   └── holiday_data.dart        -- تعطیلات ثابت
│   ├── theme/app_theme.dart
│   └── utils/
│       ├── jalali_helper.dart
│       └── debt_calculator.dart     -- منطق بدهی از monthly_fee_records
├── data/
│   ├── database/
│   │   ├── database_helper.dart     -- onCreate schema v2.1
│   │   └── migrations/
│   │       └── migration_v1_v2.dart
│   ├── models/
│   │   ├── athlete.dart             🆕 (جایگزین student.dart)
│   │   ├── coach.dart
│   │   ├── session.dart
│   │   ├── attendance.dart
│   │   ├── athlete_fee_plan.dart    🆕 (جایگزین fee_history)
│   │   ├── monthly_fee_record.dart  🆕 اصلی‌ترین مدل مالی
│   │   ├── payment.dart
│   │   ├── expense.dart             🆕 (جایگزین ball_cost)
│   │   ├── makeup_debt.dart         🆕
│   │   └── iranian_holiday.dart
│   └── repositories/
│       ├── athlete_repository.dart
│       ├── session_repository.dart
│       ├── monthly_fee_repository.dart  🆕
│       ├── payment_repository.dart
│       ├── expense_repository.dart
│       └── report_repository.dart
└── presentation/
    ├── providers/
    │   ├── athlete_provider.dart
    │   ├── session_provider.dart
    │   └── finance_provider.dart
    ├── screens/
    │   ├── home/home_screen.dart
    │   ├── sessions/
    │   │   ├── sessions_screen.dart
    │   │   ├── session_detail_screen.dart
    │   │   └── add_session_sheet.dart
    │   ├── athletes/                 🆕 (جایگزین students)
    │   │   ├── athletes_screen.dart
    │   │   ├── athlete_profile_screen.dart
    │   │   └── fee_plan_history_screen.dart
    │   ├── finances/
    │   │   ├── finances_screen.dart
    │   │   ├── add_payment_sheet.dart
    │   │   └── add_expense_sheet.dart
    │   ├── reports/reports_screen.dart
    │   └── settings/settings_screen.dart
    └── widgets/
        ├── stat_card.dart
        ├── debt_badge.dart
        ├── monthly_record_tile.dart  🆕
        └── jalali_date_picker.dart
```

---

# ═══════════════════════════════════════
# بخش ۶ — منطق کلیدی (Debt Calculator)
# ═══════════════════════════════════════

## محاسبه بدهی ورزشکار

```dart
// debt_calculator.dart

class DebtCalculator {

  // بدهی کل یک ورزشکار (تمام ماه‌ها)
  static Future<int> totalDebt(int athleteId, Database db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_due - amount_paid), 0) as debt
      FROM monthly_fee_records
      WHERE athlete_id = ? AND status != 'waived'
    ''', [athleteId]);
    return result.first['debt'] as int;
  }

  // بدهی یک ماه خاص
  static Future<int> monthDebt(int athleteId, int year, int month, Database db) async {
    final result = await db.query('monthly_fee_records',
      where: 'athlete_id = ? AND jalali_year = ? AND jalali_month = ?',
      whereArgs: [athleteId, year, month]);
    if (result.isEmpty) return 0;
    final rec = result.first;
    return (rec['amount_due'] as int) - (rec['amount_paid'] as int);
  }

  // به‌روزرسانی amount_paid بعد از پرداخت
  static Future<void> applyPayment(int recordId, int amount, Database db) async {
    await db.rawUpdate('''
      UPDATE monthly_fee_records
      SET amount_paid = amount_paid + ?,
          status = CASE
            WHEN amount_paid + ? >= amount_due THEN 'settled'
            WHEN amount_paid + ? > 0           THEN 'partial'
            ELSE 'pending'
          END
      WHERE id = ?
    ''', [amount, amount, amount, recordId]);
  }

  // ساخت رکورد ماه جدید برای ورزشکار ماهانه
  static Future<void> createMonthlyRecord(
    int athleteId, int year, int month, Database db
  ) async {
    // گرفتن نرخ فعلی
    final plan = await db.rawQuery('''
      SELECT fee_type, fee_amount FROM athlete_fee_plans
      WHERE athlete_id = ? AND effective_to IS NULL
      ORDER BY effective_from DESC LIMIT 1
    ''', [athleteId]);
    if (plan.isEmpty) return;

    final feeType = plan.first['fee_type'] as String;
    final feeAmount = plan.first['fee_amount'] as int;

    // برای جلسه‌ای، amount_due در ابتدا 0 است (با هر حضور افزایش می‌یابد)
    await db.insert('monthly_fee_records', {
      'athlete_id': athleteId,
      'jalali_year': year,
      'jalali_month': month,
      'fee_type': feeType,
      'amount_due': feeType == 'monthly' ? feeAmount : 0,
      'amount_paid': 0,
      'sessions_count': 0,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // به‌روزرسانی رکورد جلسه‌ای بعد از ثبت حضور
  static Future<void> updateSessionFeeRecord(
    int athleteId, int year, int month, Database db
  ) async {
    final plan = await db.rawQuery('''
      SELECT fee_amount FROM athlete_fee_plans
      WHERE athlete_id = ? AND effective_to IS NULL LIMIT 1
    ''', [athleteId]);
    if (plan.isEmpty) return;

    final rate = plan.first['fee_amount'] as int;

    // تعداد جلسات عادی (نه جبرانی) که ورزشکار در آن‌ها حاضر بوده
    final count = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM attendance a
      JOIN sessions s ON a.session_id = s.id
      WHERE a.athlete_id = ?
        AND s.jalali_year = ?
        AND s.jalali_month = ?
        AND a.present = 1
        AND a.is_makeup_attendance = 0
        AND s.session_type = 'regular'
    ''', [athleteId, year, month]);

    final sessionCount = count.first['cnt'] as int;
    final newAmountDue = sessionCount * rate;

    await db.rawUpdate('''
      UPDATE monthly_fee_records
      SET sessions_count = ?,
          amount_due = ?,
          status = CASE
            WHEN amount_paid >= ? AND ? > 0 THEN 'settled'
            WHEN amount_paid > 0            THEN 'partial'
            ELSE 'pending'
          END
      WHERE athlete_id = ? AND jalali_year = ? AND jalali_month = ?
    ''', [sessionCount, newAmountDue, newAmountDue, newAmountDue,
          athleteId, year, month]);
  }
}
```

---

# ═══════════════════════════════════════
# بخش ۷ — چک‌لیست پیاده‌سازی
# ═══════════════════════════════════════

## فاز ۱ — پایه داده (بدون این‌ها اپ کار نمی‌کند)

- [ ] `database_helper.dart` — schema v2.1 کامل (onCreate)
- [ ] `migration_v1_v2.dart` — ۱۱ مرحله migration
- [ ] `athlete.dart` — model
- [ ] `athlete_fee_plan.dart` — model
- [ ] `monthly_fee_record.dart` — model (مهم‌ترین)
- [ ] `session.dart` — با jalali_year/month/time
- [ ] `attendance.dart` — با athlete_id
- [ ] `payment.dart` — با monthly_fee_record_id
- [ ] `expense.dart` — با category enum
- [ ] `makeup_debt.dart` — model
- [ ] `debt_calculator.dart` — منطق کامل

## فاز ۲ — Repository Layer

- [ ] `athlete_repository.dart` — CRUD + fee plan management
- [ ] `session_repository.dart` — CRUD + attendance + jalali filter
- [ ] `monthly_fee_repository.dart` — create/update/query records
- [ ] `payment_repository.dart` — with record linking
- [ ] `expense_repository.dart`
- [ ] `report_repository.dart` — monthly/coach/athlete reports

## فاز ۳ — UI (ورزشکار‌محور)

- [ ] `athletes_screen.dart` — لیست با badge بدهی
- [ ] `athlete_profile_screen.dart` — ۴ tab کامل
- [ ] `fee_plan_history_screen.dart`
- [ ] `sessions_screen.dart` — با تقویم
- [ ] `session_detail_screen.dart` — حضور و غیاب
- [ ] `finances_screen.dart` — ۳ tab
- [ ] `add_payment_sheet.dart` — با انتخاب ماه
- [ ] `add_expense_sheet.dart` — با category grid
- [ ] `home_screen.dart` — dashboard با بدهکاران
- [ ] `reports_screen.dart` — ۴ tab

## فاز ۴ — تکمیلی

- [ ] Backup Lite / Full
- [ ] Jalali Date Picker widget
- [ ] تعطیلات مذهبی متغیر (Settings)
- [ ] Export گزارش (share text)
