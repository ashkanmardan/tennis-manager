# FINAL DESIGN DOCUMENT
## Tennis Manager App — v2.0
### Database Design + ER Diagram + Migration Plan + Screen Map

---

# ═══════════════════════════════════════
# بخش ۱ — Database Final Design (v2)
# ═══════════════════════════════════════

## اصول طراحی

- **Student-centric:** شاگرد مالک داده است، نه جلسه
- **Fee History:** شهریه ثابت نیست — تاریخچه کامل نگه داشته می‌شود
- **Coach Independence:** هر مربی پرونده مستقل دارد
- **Jalali-native:** ماه و سال جلالی در جداول ذخیره می‌شود برای query سریع
- **Offline-first:** تمام داده‌ها در SQLite محلی

---

## جدول ۱ — coaches (مربیان)

```sql
CREATE TABLE coaches (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  phone         TEXT,
  is_active     INTEGER NOT NULL DEFAULT 1,       -- فقط یکی active است
  start_date    TEXT    NOT NULL,                 -- ISO date (میلادی)
  end_date      TEXT,                             -- null یعنی هنوز فعال
  notes         TEXT,
  created_at    TEXT    NOT NULL
);
```

**قوانین:**
- هر بار که مربی جدید اضافه می‌شود، مربی قبلی `end_date` می‌گیرد
- `is_active = 1` فقط برای یک رکورد در هر زمان
- حذف مربی ممنوع — فقط غیرفعال می‌شود (تاریخچه حفظ)

---

## جدول ۲ — students (شاگردان)

```sql
CREATE TABLE students (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  phone         TEXT,
  birth_date    TEXT,                             -- اختیاری، جلالی
  is_active     INTEGER NOT NULL DEFAULT 1,
  join_date     TEXT    NOT NULL,                 -- تاریخ شروع، جلالی ISO
  notes         TEXT,
  created_at    TEXT    NOT NULL
);
```

**تغییر از v1:**
- حذف `fee_type` و `fee_amount` — به `fee_history` منتقل شدند
- اضافه شد `birth_date`
- تغییر نام `created_at` به `join_date` (معنادارتر)

---

## جدول ۳ — fee_history (تاریخچه شهریه) 🆕

```sql
CREATE TABLE fee_history (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id       INTEGER NOT NULL,
  fee_type         TEXT    NOT NULL,   -- 'monthly' | 'session'
  fee_amount       INTEGER NOT NULL,   -- مبلغ به تومان
  effective_from   TEXT    NOT NULL,   -- جلالی ISO: 1403-01-01
  effective_to     TEXT,               -- null یعنی تا الان معتبر است
  notes            TEXT,
  created_at       TEXT    NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id)
);
```

**قوانین:**
- وقتی شهریه تغییر کند: رکورد قبلی `effective_to` می‌گیرد، رکورد جدید اضافه می‌شود
- محاسبه بدهی هر ماه باید از این جدول بخواند
- فقط یک رکورد با `effective_to = NULL` برای هر student معتبر است

**مثال:**
```
student_id=1 | monthly | 800000 | from: 1402-07-01 | to: 1403-01-01
student_id=1 | monthly | 900000 | from: 1403-01-01 | to: NULL
```

---

## جدول ۴ — sessions (جلسات)

```sql
CREATE TABLE sessions (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  date                TEXT    NOT NULL,             -- YYYY-MM-DD میلادی
  jalali_year         INTEGER NOT NULL,             -- سال جلالی (برای query)
  jalali_month        INTEGER NOT NULL,             -- ماه جلالی (برای query)
  time                TEXT,                         -- HH:MM (اختیاری)
  duration_minutes    INTEGER DEFAULT 60,
  session_type        TEXT    NOT NULL DEFAULT 'regular',  -- regular | makeup
  coach_id            INTEGER,
  venue               TEXT,
  coach_cancelled     INTEGER NOT NULL DEFAULT 0,
  requires_makeup     INTEGER NOT NULL DEFAULT 0,
  original_session_id INTEGER,                      -- برای makeup: جلسه اصلی
  notes               TEXT,
  created_at          TEXT    NOT NULL,
  FOREIGN KEY (coach_id) REFERENCES coaches(id),
  FOREIGN KEY (original_session_id) REFERENCES sessions(id)
);
```

**تغییر از v1:**
- اضافه شد: `jalali_year`, `jalali_month`, `time`, `duration_minutes`
- `jalali_year/month` هنگام insert محاسبه و ذخیره می‌شوند (query سریع)

---

## جدول ۵ — attendance (حضور و غیاب)

```sql
CREATE TABLE attendance (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id            INTEGER NOT NULL,
  student_id            INTEGER NOT NULL,
  present               INTEGER NOT NULL DEFAULT 1,
  is_makeup_attendance  INTEGER NOT NULL DEFAULT 0,  -- این حضور، جبرانی است
  makeup_debt_id        INTEGER,                     -- کدام بدهی جبرانی تسویه شد
  notes                 TEXT,
  FOREIGN KEY (session_id)   REFERENCES sessions(id)   ON DELETE CASCADE,
  FOREIGN KEY (student_id)   REFERENCES students(id),
  FOREIGN KEY (makeup_debt_id) REFERENCES makeup_debts(id),
  UNIQUE(session_id, student_id)
);
```

**تغییر از v1:**
- `is_makeup_for` → `is_makeup_attendance` (نام واضح‌تر)
- `makeup_for_session_id` → `makeup_debt_id` (اتصال به جدول makeup_debts)

---

## جدول ۶ — makeup_debts (بدهی جبرانی) 🆕

```sql
CREATE TABLE makeup_debts (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id          INTEGER NOT NULL,
  session_id          INTEGER NOT NULL,   -- جلسه‌ای که بدهی ایجاد کرد
  reason              TEXT    NOT NULL,   -- 'student_absent' | 'coach_cancelled'
  is_settled          INTEGER NOT NULL DEFAULT 0,
  settled_session_id  INTEGER,            -- جلسه جبرانی که تسویه کرد
  settled_at          TEXT,
  notes               TEXT,
  created_at          TEXT    NOT NULL,
  FOREIGN KEY (student_id)          REFERENCES students(id),
  FOREIGN KEY (session_id)          REFERENCES sessions(id),
  FOREIGN KEY (settled_session_id)  REFERENCES sessions(id)
);
```

**قوانین:**
- وقتی مربی جلسه لغو کند و `requires_makeup = 1`:
  → یک رکورد برای هر شاگرد حاضر ساخته می‌شود
- وقتی شاگرد جلسه جبرانی برگزار کند:
  → `is_settled = 1` و `settled_session_id` پر می‌شود
- جلسه جبرانی **شهریه ندارد** → در محاسبه بدهی مالی حذف می‌شود

---

## جدول ۷ — payments (پرداخت‌ها)

```sql
CREATE TABLE payments (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id      INTEGER NOT NULL,
  amount          INTEGER NOT NULL,
  date            TEXT    NOT NULL,
  jalali_year     INTEGER NOT NULL,    -- برای query سریع
  jalali_month    INTEGER NOT NULL,    -- برای query سریع
  payment_for     TEXT    NOT NULL DEFAULT 'tuition',  -- tuition | expense
  expense_id      INTEGER,             -- اگه برای هزینه جانبی است
  description     TEXT,
  receipt_image_path TEXT,
  receipt_note    TEXT,
  created_at      TEXT    NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (expense_id) REFERENCES expenses(id)
);
```

**تغییر از v1:**
- اضافه شد: `jalali_year`, `jalali_month`, `expense_id`
- حذف شد: `session_id` (پرداخت به جلسه خاص وابسته نیست)
- `payment_for` الان می‌تواند `expense` هم باشد

---

## جدول ۸ — expenses (هزینه‌های جانبی) 🆕 جایگزین ball_costs

```sql
CREATE TABLE expenses (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  date            TEXT    NOT NULL,
  jalali_year     INTEGER NOT NULL,
  jalali_month    INTEGER NOT NULL,
  category        TEXT    NOT NULL,
  -- مقادیر: ball | racket | stringing | grip | shoe |
  --         clothing | tournament | transport | other
  amount          INTEGER NOT NULL,
  student_id      INTEGER,     -- null = هزینه عمومی کلاس
  session_id      INTEGER,     -- null = مستقل از جلسه
  description     TEXT,
  receipt_image_path TEXT,
  created_at      TEXT    NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

---

## جدول ۹ — iranian_holidays (تعطیلات رسمی ایران) 🆕

```sql
CREATE TABLE iranian_holidays (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  jalali_month  INTEGER NOT NULL,
  jalali_day    INTEGER NOT NULL,
  title         TEXT    NOT NULL,
  is_recurring  INTEGER NOT NULL DEFAULT 1,  -- هر سال تکرار می‌شود
  jalali_year   INTEGER                       -- null یعنی تکرار سالانه
);
```

**داده‌های اولیه (pre-loaded):**
```
1/1  نوروز
1/2  نوروز
1/3  نوروز
1/4  نوروز
1/13 سیزده به در
3/14 رحلت امام خمینی
3/15 قیام ۱۵ خرداد
11/22 پیروزی انقلاب اسلامی
12/29 ملی شدن صنعت نفت
+ تعطیلات مذهبی متغیر (باید جداگانه وارد شوند)
```

---

## ایندکس‌های پرفورمنس

```sql
-- sessions
CREATE INDEX idx_sessions_jalali ON sessions(jalali_year, jalali_month);
CREATE INDEX idx_sessions_coach  ON sessions(coach_id);
CREATE INDEX idx_sessions_date   ON sessions(date);

-- attendance
CREATE INDEX idx_att_session ON attendance(session_id);
CREATE INDEX idx_att_student ON attendance(student_id);

-- payments
CREATE INDEX idx_pay_student ON payments(student_id);
CREATE INDEX idx_pay_jalali  ON payments(jalali_year, jalali_month);

-- expenses
CREATE INDEX idx_exp_jalali  ON expenses(jalali_year, jalali_month);
CREATE INDEX idx_exp_student ON expenses(student_id);

-- fee_history
CREATE INDEX idx_fee_student ON fee_history(student_id);

-- makeup_debts
CREATE INDEX idx_mkup_student  ON makeup_debts(student_id);
CREATE INDEX idx_mkup_settled  ON makeup_debts(is_settled);
```

---

# ═══════════════════════════════════════
# بخش ۲ — ER Diagram
# ═══════════════════════════════════════

```
┌─────────────┐       ┌──────────────────┐
│   coaches   │       │  iranian_holidays │
│─────────────│       │──────────────────│
│ id          │       │ jalali_month     │
│ name        │       │ jalali_day       │
│ phone       │       │ title            │
│ is_active   │       └──────────────────┘
│ start_date  │
│ end_date    │
└──────┬──────┘
       │ 1
       │ coach_id
       │ N
┌──────┴──────┐           ┌───────────────────┐
│  sessions   │           │    fee_history     │
│─────────────│           │───────────────────│
│ id          │           │ id                │
│ date        │     ┌─────│ student_id (FK)   │
│ jalali_year │     │     │ fee_type          │
│ jalali_month│     │     │ fee_amount        │
│ time        │     │     │ effective_from    │
│ duration    │     │     │ effective_to      │
│ session_type│     │     └───────────────────┘
│ coach_id(FK)│     │
│ venue       │     │     ┌───────────────────┐
│ cancelled   │     │     │     students      │
│ req_makeup  │     │     │───────────────────│
│ original_id │     └─────│ id                │
└──────┬──────┘           │ name              │
       │                  │ phone             │
   ┌───┴────────┐         │ birth_date        │
   │            │         │ is_active         │
   │            │         │ join_date         │
   ▼            ▼         └────────┬──────────┘
┌────────────┐  ┌────────────┐    │
│ attendance │  │makeup_debts│    │
│────────────│  │────────────│    │
│ id         │  │ id         │◄───┤
│ session_id │  │ student_id │    │
│ student_id │  │ session_id │    │
│ present    │  │ reason     │    │
│ is_makeup  │  │ is_settled │    │
│ debt_id(FK)│  │ settled_at │    │
└────────────┘  └────────────┘    │
                                  │
┌─────────────────────────────────┤
│                                 │
▼                                 │
┌────────────┐  ┌──────────────┐  │
│  payments  │  │   expenses   │  │
│────────────│  │──────────────│  │
│ id         │  │ id           │  │
│ student_id │◄─┤ date         │  │
│ amount     │  │ jalali_year  │  │
│ date       │  │ jalali_month │  │
│ jal_year   │  │ category     │◄─┘
│ jal_month  │  │ amount       │
│ for        │  │ student_id   │
│ expense_id │  │ session_id   │
│ receipt    │  │ description  │
└────────────┘  └──────────────┘
```

---

# ═══════════════════════════════════════
# بخش ۳ — Migration Plan (v1 → v2)
# ═══════════════════════════════════════

## روش Migration

از آنجا که اپ هنوز در production نیست، Migration به صورت **fresh install** انجام می‌شود:
- DB version از 1 به 2 می‌رود
- `onUpgrade` در DatabaseHelper پیاده می‌شود
- برای کاربران موجود: داده از v1 به v2 منتقل می‌شود

## مراحل Migration (onUpgrade)

```sql
-- مرحله ۱: اضافه کردن ستون‌های جدید به sessions
ALTER TABLE sessions ADD COLUMN jalali_year INTEGER;
ALTER TABLE sessions ADD COLUMN jalali_month INTEGER;
ALTER TABLE sessions ADD COLUMN time TEXT;
ALTER TABLE sessions ADD COLUMN duration_minutes INTEGER DEFAULT 60;

-- مرحله ۲: پر کردن jalali_year/month از date موجود
-- (در کد Dart انجام می‌شود: loop over sessions, compute Jalali)

-- مرحله ۳: اضافه کردن ستون‌های جدید به payments
ALTER TABLE payments ADD COLUMN jalali_year INTEGER;
ALTER TABLE payments ADD COLUMN jalali_month INTEGER;
ALTER TABLE payments ADD COLUMN expense_id INTEGER;
-- حذف session_id از payments (در SQLite نمی‌توان DROP COLUMN کرد در نسخه‌های قدیمی)
-- راه حل: نادیده گرفتن ستون (backward compatible)

-- مرحله ۴: پر کردن jalali برای payments
-- (در کد Dart)

-- مرحله ۵: ساخت جدول fee_history
CREATE TABLE fee_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  fee_type TEXT NOT NULL,
  fee_amount INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  notes TEXT,
  created_at TEXT NOT NULL
);

-- مرحله ۶: انتقال شهریه فعلی از students به fee_history
-- (در کد Dart: برای هر student، یک رکورد fee_history بساز)

-- مرحله ۷: ساخت expenses و انتقال ball_costs
CREATE TABLE expenses ( ... );
INSERT INTO expenses (date, jalali_year, jalali_month, category, amount, session_id, created_at)
  SELECT date, 0, 0, 'ball', total_cost, session_id, created_at FROM ball_costs;
-- jalali_year/month بعداً در کد Dart پر می‌شوند

-- مرحله ۸: ساخت makeup_debts
CREATE TABLE makeup_debts ( ... );

-- مرحله ۹: اصلاح attendance
ALTER TABLE attendance ADD COLUMN is_makeup_attendance INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN makeup_debt_id INTEGER;

-- مرحله ۱۰: ساخت iranian_holidays و insert داده‌های اولیه
CREATE TABLE iranian_holidays ( ... );
INSERT INTO iranian_holidays ...;

-- مرحله ۱۱: ساخت ایندکس‌های جدید
CREATE INDEX ...;
```

---

# ═══════════════════════════════════════
# بخش ۴ — Screen Map نهایی
# ═══════════════════════════════════════

## ساختار Navigation

```
App Start
│
└── HomeScreen (Bottom Nav)
    ├── Tab 0: Dashboard (خانه)
    ├── Tab 1: Sessions (جلسات)
    ├── Tab 2: Students (شاگردان)
    ├── Tab 3: Finances (مالی)
    └── Tab 4: Reports (گزارش)
```

---

## Tab 0 — Dashboard (خانه)

```
┌─────────────────────────────────────┐
│  🎾 مدیریت تنیس          [⚙ Settings]│
├─────────────────────────────────────┤
│  [تاریخ جلالی امروز]                │
│  مربی فعال: [نام مربی]              │
├─────────────────────────────────────┤
│  ماه جاری — [نام ماه]               │
│  ┌──────────┐  ┌──────────┐         │
│  │ شاگرد   │  │ جلسه    │         │
│  │ فعال: N │  │ این ماه:N│         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │ بدهکار │  │ جبرانی  │         │
│  │ N نفر  │  │ بدهکار:N │         │
│  └──────────┘  └──────────┘         │
├─────────────────────────────────────┤
│  دسترسی سریع                        │
│  [+ جلسه] [+ شاگرد] [+ پرداخت]     │
│  [+ هزینه] [حضور غیاب]              │
├─────────────────────────────────────┤
│  آخرین جلسات (۳ تا)                 │
│  • ۱۵ خرداد ← جلسه عادی            │
│  • ۱۳ خرداد ← جلسه جبرانی          │
├─────────────────────────────────────┤
│  شاگردان بدهکار (هشدار)             │
│  • علی احمدی — ۲۰۰،۰۰۰ تومان       │
└─────────────────────────────────────┘
```

---

## Tab 1 — Sessions (جلسات)

```
┌─────────────────────────────────────┐
│  [< خرداد ۱۴۰۳ >]   [+ جلسه جدید] │
├─────────────────────────────────────┤
│  کل:۸ | عادی:۵ | جبرانی:۲ | لغو:۱  │
├─────────────────────────────────────┤
│  [تقویم ماهانه — نمای ماه]          │
│  ۱  ۲  ۳  ۴  ●  ۶  ۷              │
│  ۸  ۹  ●  ۱۱ ۱۲ ●  ۱۴             │
│  ...                                │
├─────────────────────────────────────┤
│  لیست جلسات این ماه                │
│  ┌─────────────────────────────────┐│
│  │🟢 ۱۵ خرداد — ۱۷:۰۰ — ۶۰ دقیقه ││
│  │   زمین شماره ۲ | مربی: احمدی   ││
│  │   حاضر: ۴/۵                    ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │🟠 ۱۳ خرداد — جبرانی            ││
│  │   برای جلسه ۱ اردیبهشت        ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
         [+ جلسه جدید]
```

### Session Detail Screen
```
┌─────────────────────────────────────┐
│ ← ۱۵ خرداد ۱۴۰۳ — ۱۷:۰۰   [ویرایش]│
├─────────────────────────────────────┤
│  🟢 جلسه عادی | زمین ۲ | ۶۰ دقیقه  │
│  مربی: علی احمدی                    │
├─────────────────────────────────────┤
│  حضور و غیاب        [همه حاضر]      │
│  ┌──────────────────────────────────┤
│  │ ● رضا محمدی       [حاضر ✓]      │
│  │ ● سارا کریمی      [حاضر ✓]      │
│  │ ● علی رضایی       [غایب ✗]      │
│  └──────────────────────────────────┤
│  [ذخیره حضور]    [ثبت هزینه توپ]   │
└─────────────────────────────────────┘
```

### Add Session Sheet
```
┌─────────────────────────────────────┐
│  ثبت جلسه جدید                  [×] │
├─────────────────────────────────────┤
│  تاریخ: [۱۵ خرداد ۱۴۰۳]  [انتخاب] │
│  ساعت: [۱۷:۰۰]  (اختیاری)         │
│  مدت: [۶۰ دقیقه]                   │
│  نوع: (●) عادی  ( ) جبرانی         │
│  مکان: [________________]           │
│  ─────────────────────────          │
│  (□) لغو شده توسط مربی              │
│      (□) نیاز به جبرانی دارد       │
│  ─────────────────────────          │
│  یادداشت: [________________]        │
│                                     │
│       [ذخیره جلسه]                 │
└─────────────────────────────────────┘
```

---

## Tab 2 — Students (شاگردان)

```
┌─────────────────────────────────────┐
│  شاگردان              [+ شاگرد جدید]│
├─────────────────────────────────────┤
│  [🔍 جستجو...]                      │
├────────────┬────────────────────────┤
│  فعال (۵) │  غیرفعال (۲)           │
├────────────┴────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ [ر] رضا محمدی                  ││
│  │     ۹۰۰،۰۰۰ ت/ماه | بدهکار ✗  ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ [س] سارا کریمی                 ││
│  │     ۵۰،۰۰۰ ت/جلسه | تسویه ✓   ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Student Detail Screen
```
┌─────────────────────────────────────┐
│ ← رضا محمدی                  [ویرایش]│
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ ⚠ بدهکار: ۲۰۰،۰۰۰ تومان       ││
│  │         [ثبت پرداخت سریع]      ││
│  └─────────────────────────────────┘│
├───────┬──────┬──────────────────────┤
│اطلاعات│مالی  │حضور  │جبرانی         │
├───────┴──────┴──────────────────────┤

--- Tab: اطلاعات ---
│  نام: رضا محمدی                    │
│  تلفن: ۰۹۱۲...                    │
│  تاریخ شروع: ۱ مهر ۱۴۰۲           │
│  شهریه فعلی: ۹۰۰،۰۰۰/ماه          │
│  [تاریخچه شهریه →]                 │

--- Tab: مالی ---
│  جمع پرداختی: ۵،۴۰۰،۰۰۰           │
│  جمع بدهی: ۵،۶۰۰،۰۰۰              │
│  مانده: ۲۰۰،۰۰۰- (بدهکار)         │
│  ────────────────────               │
│  پرداخت‌ها:                         │
│  • ۱۵ خرداد — ۹۰۰،۰۰۰ [رسید📎]   │
│  • ۱۲ اردیبهشت — ۴۵۰،۰۰۰          │

--- Tab: حضور ---
│  حاضر: ۲۴  غایب: ۳  کل: ۲۷       │
│  درصد حضور: ۸۹٪                    │
│  [نمودار حضور]                      │

--- Tab: جبرانی ---
│  بدهکار جبرانی: ۱ جلسه            │
│  • جلسه ۵ فروردین — لغو مربی      │
│    وضعیت: ⏳ در انتظار جبران       │
└─────────────────────────────────────┘
```

### Fee History Screen
```
┌─────────────────────────────────────┐
│ ← تاریخچه شهریه — رضا محمدی        │
├─────────────────────────────────────┤
│  شهریه فعلی: ۹۰۰،۰۰۰/ماه  [تغییر] │
├─────────────────────────────────────┤
│  • ماهانه ۹۰۰،۰۰۰  از ۱۴۰۳/۰۱    │
│    تا الان (فعال)                   │
│  • ماهانه ۸۰۰،۰۰۰  از ۱۴۰۲/۰۷    │
│    تا ۱۴۰۳/۰۱                      │
└─────────────────────────────────────┘
```

---

## Tab 3 — Finances (مالی)

```
┌─────────────────────────────────────┐
│  مالی                  [فیلتر ماه] │
├─────────────────────────────────────┤
│  [پرداخت‌ها] [هزینه‌ها] [بدهکاران]  │
├─────────────────────────────────────┤

--- Tab: پرداخت‌ها ---
│  ماه جاری: ۴،۵۰۰،۰۰۰ تومان        │
│  ────────────────────               │
│  • سارا کریمی — ۹۰۰،۰۰۰           │
│  • رضا محمدی — ۴۵۰،۰۰۰            │
│  [+ پرداخت جدید]                   │

--- Tab: هزینه‌ها ---
│  ماه جاری: ۱،۲۰۰،۰۰۰ تومان        │
│  توپ: ۸۰۰،۰۰۰                      │
│  زه‌کشی: ۴۰۰،۰۰۰                   │
│  ────────────────────               │
│  • ۱۵ خرداد — توپ — ۲۰۰،۰۰۰      │
│  • ۱۰ خرداد — زه‌کشی — ۴۰۰،۰۰۰   │
│  [+ هزینه جدید]                    │

--- Tab: بدهکاران ---
│  مجموع بدهی: ۱،۸۰۰،۰۰۰ تومان      │
│  ────────────────────               │
│  • رضا محمدی — ۲۰۰،۰۰۰ [پرداخت]  │
│  • علی رضایی — ۱،۶۰۰،۰۰۰ [پرداخت]│
└─────────────────────────────────────┘
```

### Add Expense Sheet
```
┌─────────────────────────────────────┐
│  ثبت هزینه                      [×] │
├─────────────────────────────────────┤
│  دسته‌بندی:                         │
│  [🎾توپ][🏏راکت][🔗زه‌کشی][✊گریپ] │
│  [👟کفش][👕لباس][🏆مسابقات]        │
│  [🚗رفت‌وآمد][📋سایر]              │
│  ────────────────────               │
│  مبلغ: [___________] تومان         │
│  تاریخ: [۱۵ خرداد ۱۴۰۳]           │
│  مربوط به شاگرد: [انتخاب/همه]     │
│  توضیح: [___________]              │
│  رسید: [📸 عکس]                    │
│                                     │
│        [ذخیره هزینه]               │
└─────────────────────────────────────┘
```

---

## Tab 4 — Reports (گزارش)

```
┌─────────────────────────────────────┐
│  گزارش            [< خرداد ۱۴۰۳ >] │
├─────────────────────────────────────┤
│  [ماهانه] [مربی] [شاگرد] [سالانه]  │
├─────────────────────────────────────┤

--- Tab: ماهانه ---
│  📅 جلسات                           │
│  کل: ۸ | عادی: ۵ | جبرانی: ۲ | لغو:۱│
│                                     │
│  💰 درآمد                           │
│  دریافتی: ۴،۵۰۰،۰۰۰               │
│  هزینه‌ها: ۱،۲۰۰،۰۰۰               │
│  سود خالص: ۳،۳۰۰،۰۰۰               │
│                                     │
│  👥 شاگردان                         │
│  فعال: ۵ | بدهکار: ۲               │
│                                     │
│  📊 وضعیت بدهی                      │
│  • رضا محمدی ——— ۲۰۰،۰۰۰ بدهکار   │
│  • سارا کریمی ——— تسویه ✓           │

--- Tab: مربی ---
│  فیلتر بر اساس مربی:               │
│  [مربی فعلی: احمدی ▼]              │
│  دوره: ۱۴۰۳/۰۱ تا الان            │
│  ────────────────────               │
│  جلسات: ۴۵                         │
│  درآمد: ۲۲،۵۰۰،۰۰۰                │
│  جبرانی‌های بدهکار: ۳              │

--- Tab: شاگرد ---
│  [انتخاب شاگرد ▼]                  │
│  گزارش کامل رضا محمدی             │
│  ────────────────────               │
│  حضور: ۸۹٪ | بدهی: ۲۰۰،۰۰۰       │
│  جلسات جبرانی بدهکار: ۱           │
│  تاریخچه پرداخت: [نمودار]          │
└─────────────────────────────────────┘
```

---

## Settings Screen

```
┌─────────────────────────────────────┐
│ ← تنظیمات                           │
├─────────────────────────────────────┤
│  🧑‍🏫 مربی                            │
│  مربی فعال: احمدی [تغییر]           │
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
│  اشکان مردانپور                     │
│  ۰۹۱۸۸۵۹۳۸۹۷                      │
│  نسخه ۲.۰.۰                        │
└─────────────────────────────────────┘
```

---

# ═══════════════════════════════════════
# بخش ۵ — معماری کد (v2)
# ═══════════════════════════════════════

## ساختار پوشه‌ها (نهایی)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── expense_categories.dart  🆕
│   │   └── iranian_holidays_data.dart  🆕
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── jalali_helper.dart
│       ├── number_formatter.dart
│       └── debt_calculator.dart  🆕
├── data/
│   ├── database/
│   │   ├── database_helper.dart  (refactored)
│   │   └── migrations/
│   │       └── migration_v1_to_v2.dart  🆕
│   ├── models/
│   │   ├── student.dart          (refactored)
│   │   ├── coach.dart
│   │   ├── session.dart          (refactored)
│   │   ├── attendance.dart       (refactored)
│   │   ├── payment.dart          (refactored)
│   │   ├── expense.dart          🆕 (جایگزین ball_cost)
│   │   ├── fee_history.dart      🆕
│   │   ├── makeup_debt.dart      🆕
│   │   └── iranian_holiday.dart  🆕
│   └── repositories/
│       ├── student_repository.dart  🆕 (جدا از هم)
│       ├── session_repository.dart  🆕
│       ├── payment_repository.dart  🆕
│       ├── expense_repository.dart  🆕
│       └── report_repository.dart   🆕
└── presentation/
    ├── providers/
    │   ├── student_provider.dart   🆕
    │   ├── session_provider.dart   🆕
    │   └── finance_provider.dart   🆕
    ├── screens/
    │   ├── home/
    │   ├── sessions/
    │   ├── students/
    │   │   ├── students_screen.dart
    │   │   ├── student_detail_screen.dart
    │   │   └── fee_history_screen.dart  🆕
    │   ├── finances/           🆕 (جایگزین payments)
    │   │   ├── finances_screen.dart
    │   │   ├── add_payment_screen.dart
    │   │   └── add_expense_screen.dart  🆕
    │   ├── reports/
    │   └── settings/
    └── widgets/
        ├── stat_card.dart
        ├── debt_badge.dart  🆕
        └── jalali_date_picker.dart  🆕
```

---

# ═══════════════════════════════════════
# بخش ۶ — چک‌لیست پیاده‌سازی
# ═══════════════════════════════════════

## فاز اول — پایه (بدون این‌ها اپ قابل استفاده نیست)

- [ ] DB Schema v2 (تمام جداول)
- [ ] Migration v1→v2
- [ ] fee_history model + repo
- [ ] expense model + repo (جایگزین ball_cost)
- [ ] makeup_debt model + repo
- [ ] debt_calculator با منطق درست جلالی
- [ ] اصلاح session model (jalali_year/month + time)
- [ ] اصلاح payment model (jalali_year/month)
- [ ] Pre-load Iranian holidays

## فاز دوم — UI اصلی

- [ ] Dashboard با هشدار بدهکاران
- [ ] Sessions با تقویم ماهانه
- [ ] Student Detail با ۴ tab
- [ ] Fee History Screen
- [ ] Finances Screen با ۳ tab
- [ ] Add Expense با دسته‌بندی
- [ ] Reports با فیلتر مربی

## فاز سوم — تکمیلی

- [ ] Backup Lite / Full
- [ ] Jalali Date Picker
- [ ] Export ساده (share text)
- [ ] مدیریت تعطیلات مذهبی متغیر
