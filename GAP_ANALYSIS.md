# GAP ANALYSIS — Tennis Manager App
## تحلیل اختلاف پروژه فعلی با PRD نهایی

تاریخ تحلیل: ۱۴۰۵/۰۳/۱۶  
نسخه پروژه: Draft v1  
تحلیلگر: Claude AI

---

## بخش ۱ — وضعیت کلی پروژه فعلی

### ساختار پوشه‌ها
```
lib/
├── core/
│   ├── constants/app_constants.dart      ✓
│   ├── theme/app_theme.dart              ✓
│   └── utils/
│       ├── jalali_helper.dart            ✓
│       └── number_formatter.dart         ✓
├── data/
│   ├── database/database_helper.dart     ⚠ ناقص
│   ├── models/                           ⚠ ناقص
│   └── repositories/app_repository.dart ⚠ ناقص
└── presentation/
    ├── screens/                          ⚠ ناقص
    └── widgets/stat_card.dart            ✓
```

### مدل‌های موجود
| موجودیت | وضعیت |
|---------|--------|
| Student | ⚠ ناقص — بدون تاریخچه شهریه |
| Coach | ⚠ ناقص — بدون پرونده مستقل |
| Session | ⚠ ناقص — بدون فیلد زمان |
| Attendance | ⚠ ناقص — منطق جبرانی ضعیف |
| Payment | ⚠ ناقص — بدون تفکیک دوره |
| BallCost | ❌ اشتباه — باید Expense با دسته‌بندی باشد |

---

## بخش ۲ — موارد مطابق PRD ✅

- RTL + فارسی + تقویم جلالی: **پیاده شده**
- آفلاین‌اول (SQLite): **پیاده شده**
- یک مربی فعال در یک زمان: **پیاده شده**
- مدل شهریه ماهانه و جلسه‌ای: **پایه پیاده شده**
- پرداخت با رسید تصویری/متنی: **جزئی پیاده شده**
- Backup/Restore پایه: **پیاده شده**
- تاریخچه مربیان: **پایه پیاده شده**
- لغو جلسه توسط مربی: **پیاده شده**
- چند جلسه در یک روز: **پشتیبانی می‌شود** ✓

---

## بخش ۳ — موارد ناقص ⚠️

### ۳.۱ مدل شهریه
**وضعیت فعلی:**
- `fee_type` و `fee_amount` روی موجودیت Student ثابت است
- بدهی = (ماه‌های ثبت‌نام × شهریه) - کل پرداختی

**چه چیزی کم است:**
- تاریخچه تغییر شهریه ندارد
- اگر شهریه تغییر کند، محاسبه اشتباه می‌شود
- پرداخت چند مرحله‌ای ثبت می‌شود اما در بدهی به‌درستی حساب نمی‌شود
- ماه‌بندی جلالی در محاسبه بدهی استفاده نمی‌شود (`_monthsSince` گرگوری است)

### ۳.۲ منطق جبرانی
**وضعیت فعلی:**
- Session دارای `coach_cancelled` و `requires_makeup` است
- `original_session_id` وجود دارد

**چه چیزی کم است:**
- در `getStudentDebt`، جلسات جبرانی بدهی را صفر نمی‌کنند
- اگر مربی لغو کند **بدون** نیاز به جبرانی، هنوز شهریه حساب می‌شود
- وضعیت جبرانی هر شاگرد به‌صورت مستقل پیگیری نمی‌شود

### ۳.۳ پرونده مربی
**وضعیت فعلی:**
- Coach فقط name/phone/start_date/end_date دارد
- فیلتر جلسات بر اساس مربی وجود دارد (coach_id)

**چه چیزی کم است:**
- گزارش مستقل هر مربی وجود ندارد
- سود/درآمد جداگانه هر مربی محاسبه نمی‌شود

### ۳.۴ Backup
**وضعیت فعلی:**
- یک نوع Backup (JSON بدون تصاویر)

**چه چیزی کم است:**
- Backup Lite: بدون تصاویر ❌
- Backup Full: با تصاویر ❌ (هنوز دو حالت مجزا نیست)

---

## بخش ۴ — موارد اشتباه طراحی شده ❌

### ❌ اشتباه ۱ — دیدگاه سیستم: آموزشگاه‌محور vs ورزشکارمحور

**وضعیت فعلی:**
سیستم از دید **مدیریت آموزشگاه** طراحی شده:
- Session موجودیت اصلی است
- Students به Session وابسته‌اند (Attendance)
- گزارش‌ها بر اساس Session هستند

**چه باید باشد:**
سیستم باید از دید **ورزشکار** طراحی شود:
- **Student/Athlete** موجودیت اصلی است
- هر شاگرد پرونده مستقل دارد
- جلسات به شاگرد تعلق دارند، نه برعکس
- هم‌کلاسی‌ها فقط داده جانبی هستند

**اثر:** لازم نیست معماری کامل تغییر کند، اما باید:
1. نمای اصلی اپ از Student شروع شود نه Session
2. گزارش‌ها Student-centric باشند
3. هر شاگرد dashboard مستقل داشته باشد

### ❌ اشتباه ۲ — BallCost به‌جای Expense

**وضعیت فعلی:**
```dart
class BallCost {
  final int totalCost;
  final int? sessionId;
  ...
}
```
یک جدول مجزا فقط برای توپ.

**چه باید باشد:**
```dart
class Expense {
  final String category; // ball, racket, stringing, grip, shoe, ...
  final int amount;
  final int? studentId; // می‌تواند به شاگرد وابسته باشد یا نباشد
  final int? sessionId;
  ...
}
```

### ❌ اشتباه ۳ — محاسبه بدهی با Gregorian calendar

```dart
int _monthsSince(DateTime date) {
  final now = DateTime.now();
  return (now.year - date.year) * 12 + now.month - date.month;
}
```
این محاسبه از تقویم میلادی استفاده می‌کند. باید جلالی باشد.

### ❌ اشتباه ۴ — بدهی کل به‌جای بدهی ماهانه

```dart
final monthsActive = _monthsSince(student.createdAt);
final totalOwed = monthsActive * student.feeAmount;
```
این بدهی از ابتدا تا الان را محاسبه می‌کند، نه بدهی ماه جاری.

### ❌ اشتباه ۵ — `getMonthlyReport` هزینه توپ را برای همه زمان‌ها جمع می‌کند

```dart
final ballCostTotal = await _db.getTotalBallCosts(); // بدون فیلتر ماه!
```

---

## بخش ۵ — موارد Refactor لازم 🔧

| شماره | فایل | مشکل | اولویت |
|-------|------|-------|--------|
| R1 | `app_repository.dart` | همه state در یک Provider — باید جدا شود | بالا |
| R2 | `database_helper.dart` | `getSessionsInMonth` فیلتر نمی‌کند، همه رو برمی‌گردونه | بالا |
| R3 | `app_repository.dart` | `getStudentDebt` از Gregorian استفاده می‌کند | بالا |
| R4 | `app_repository.dart` | `getMonthlyReport` هزینه توپ را بدون فیلتر جمع می‌زند | بالا |
| R5 | `session.dart` | فیلد `time` وجود ندارد | متوسط |
| R6 | `student.dart` | تاریخچه شهریه وجود ندارد | بالا |
| R7 | `ball_cost.dart` | باید به `expense.dart` تبدیل شود | بالا |
| R8 | `home_screen.dart` | Quick Actions هیچ‌کدام به جایی navigate نمی‌کنند | بالا |
| R9 | `settings_screen.dart` | `_exportBackup` ایراد ساختاری دارد | متوسط |

---

## بخش ۶ — موارد اصلاً وجود ندارند ❌❌

| شماره | قابلیت | توضیح |
|-------|--------|--------|
| M1 | تاریخچه شهریه | `fee_history` table — وقتی شهریه عوض شد چه بود |
| M2 | ماهنامه جبرانی | tracking اینکه کدام شاگرد چند جبرانی بدهکار است |
| M3 | دسته‌بندی هزینه‌ها | راکت، زه‌کشی، گریپ، کفش، لباس، مسابقات، رفت‌وآمد |
| M4 | تعطیلات رسمی ایران | جدول offline تعطیلات |
| M5 | فیلد زمان جلسه | `time` در Session — برای چند جلسه در روز با زمان مختلف |
| M6 | داشبورد Student-centric | هر شاگرد صفحه اصلی مستقل با وضعیت کامل |
| M7 | گزارش مستقل مربی | فیلتر همه داده‌ها بر اساس دوره مربی |
| M8 | اعلان‌های شهریه | reminder برای شاگردانی که بدهکارند |
| M9 | Export PDF/Excel | خروجی گزارش |
| M10 | جستجو در جلسات | فیلتر بر اساس تاریخ، مربی، مکان |

---

## بخش ۷ — طراحی دیتابیس نهایی

### جداول موجود (با تغییر)

```sql
-- بدون تغییر اساسی
CREATE TABLE coaches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  start_date TEXT NOT NULL,  -- جلالی ISO
  end_date TEXT,
  notes TEXT
);

-- تغییر: حذف fee_type و fee_amount (به fee_history منتقل می‌شود)
CREATE TABLE students (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  birth_date TEXT,           -- اضافه شد
  is_active INTEGER NOT NULL DEFAULT 1,
  join_date TEXT NOT NULL,   -- تغییر نام از created_at
  notes TEXT
);

-- تغییر: اضافه شدن فیلد time
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,        -- YYYY-MM-DD
  time TEXT,                 -- HH:MM (اختیاری)
  duration_minutes INTEGER DEFAULT 60,
  session_type TEXT NOT NULL DEFAULT 'regular',
  coach_id INTEGER,
  venue TEXT,
  coach_cancelled INTEGER NOT NULL DEFAULT 0,
  requires_makeup INTEGER NOT NULL DEFAULT 0,
  original_session_id INTEGER,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (coach_id) REFERENCES coaches(id),
  FOREIGN KEY (original_session_id) REFERENCES sessions(id)
);

-- بدون تغییر اساسی
CREATE TABLE attendance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  student_id INTEGER NOT NULL,
  present INTEGER NOT NULL DEFAULT 1,
  is_makeup_for INTEGER NOT NULL DEFAULT 0,
  makeup_for_session_id INTEGER,
  notes TEXT,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id),
  UNIQUE(session_id, student_id)
);

-- تغییر: اضافه شدن coach_id و jalali_month برای گزارش‌گیری
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  date TEXT NOT NULL,
  description TEXT,
  receipt_image_path TEXT,
  receipt_note TEXT,
  payment_for TEXT NOT NULL DEFAULT 'tuition',  -- tuition | expense
  expense_id INTEGER,        -- اتصال به جدول expenses
  jalali_year INTEGER,       -- برای گزارش سریع
  jalali_month INTEGER,      -- برای گزارش سریع
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (expense_id) REFERENCES expenses(id)
);
```

### جداول جدید

```sql
-- تاریخچه شهریه هر شاگرد
CREATE TABLE fee_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  fee_type TEXT NOT NULL,    -- monthly | session
  fee_amount INTEGER NOT NULL,
  effective_from TEXT NOT NULL,   -- از این تاریخ جلالی
  effective_to TEXT,              -- تا این تاریخ (null = تا الان)
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id)
);

-- هزینه‌های جانبی (جایگزین ball_costs)
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  category TEXT NOT NULL,   -- ball | racket | stringing | grip | shoe
                            -- clothing | tournament | transport | other
  amount INTEGER NOT NULL,
  student_id INTEGER,        -- null = هزینه عمومی کلاس
  session_id INTEGER,
  description TEXT,
  receipt_image_path TEXT,
  jalali_year INTEGER,
  jalali_month INTEGER,
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);

-- بدهی جبرانی هر شاگرد
CREATE TABLE makeup_debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  session_id INTEGER NOT NULL,   -- جلسه‌ای که غیبت کرد یا مربی لغو کرد
  is_settled INTEGER NOT NULL DEFAULT 0,
  settled_session_id INTEGER,    -- جلسه جبرانی که تسویه کرد
  settled_at TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (session_id) REFERENCES sessions(id),
  FOREIGN KEY (settled_session_id) REFERENCES sessions(id)
);

-- تعطیلات رسمی ایران (static data)
CREATE TABLE iranian_holidays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  jalali_month INTEGER NOT NULL,
  jalali_day INTEGER NOT NULL,
  title TEXT NOT NULL,
  is_recurring INTEGER NOT NULL DEFAULT 1  -- هر سال تکرار می‌شود
);
```

---

## بخش ۸ — ER Diagram

```
students ──────────────── fee_history
    │                         │
    │                    (effective_from/to)
    │
    ├──── attendance ──── sessions ──── coaches
    │          │               │
    │     (present)        (coach_id)
    │
    ├──── payments ──── expenses
    │
    └──── makeup_debts ──── sessions (settled_session_id)


expenses:
    ├── student_id (optional)
    └── session_id (optional)

sessions:
    ├── coach_id
    ├── original_session_id (self-ref برای جبرانی)
    └── iranian_holidays (date lookup)
```

---

## بخش ۹ — Migration Plan

### فاز ۱ — فوری (باید قبل از اولین اجرا انجام شود)

1. **جایگزینی `ball_costs` با `expenses`**
   - جدول `expenses` با دسته‌بندی
   - داده‌های قدیمی به category='ball' منتقل می‌شوند

2. **اضافه کردن `fee_history`**
   - مقادیر فعلی `fee_type/fee_amount` از students خوانده شده
   - به `fee_history` منتقل می‌شوند با `effective_from = join_date`
   - فیلدهای قدیمی از students حذف می‌شوند

3. **اضافه کردن `time` به sessions**
   - فیلد nullable — برای جلسات قدیمی null می‌ماند

4. **اصلاح محاسبه بدهی**
   - استفاده از `fee_history` برای هر دوره
   - استفاده از تقویم جلالی برای ماه‌بندی

### فاز ۲ — بهبود UI

1. Dashboard Student-centric در صفحه اصلی
2. گزارش مستقل مربی
3. ثبت هزینه با دسته‌بندی
4. Backup Lite vs Full

### فاز ۳ — قابلیت‌های اضافی

1. تعطیلات رسمی ایران
2. Export PDF
3. اعلان‌های بدهی

---

## بخش ۱۰ — خلاصه اولویت‌بندی Refactor

| اولویت | کار | تأثیر |
|--------|-----|-------|
| 🔴 بحرانی | اصلاح محاسبه بدهی (Jalali) | داده نادرست |
| 🔴 بحرانی | جایگزینی BallCost با Expense | معماری اشتباه |
| 🔴 بحرانی | اضافه کردن fee_history | داده ناقص |
| 🔴 بحرانی | اصلاح getMonthlyReport (فیلتر ماه) | گزارش نادرست |
| 🟡 مهم | اضافه کردن makeup_debts table | منطق ناقص |
| 🟡 مهم | Dashboard Student-centric | UX |
| 🟡 مهم | اضافه کردن time به Session | داده ناقص |
| 🟢 بهبود | تعطیلات ایران | offline data |
| 🟢 بهبود | Backup Lite/Full | قابلیت PRD |
| 🟢 بهبود | گزارش مستقل مربی | قابلیت PRD |
