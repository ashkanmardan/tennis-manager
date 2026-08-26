# Tennis Manager

Persian-first Android app for managing tennis classes, students, sessions, and payments.

## معرفی

Tennis Manager یک اپ آفلاین برای مدیریت کلاس‌های تنیس است. تمرکز آن روی ثبت شاگردها، مدیریت جلسات، حضور و غیاب، پرداخت‌ها، گزارش‌ها و پشتیبان‌گیری است.

## توضیح کوتاه

یک برنامه اندرویدی برای مدیریت کلاس تنیس، شاگردها، جلسه‌ها و پرداخت‌ها با رابط فارسی و آفلاین.

## Features

- Persian RTL interface
- Jalali calendar support
- Offline-first workflow
- Student management
- Session scheduling and tracking
- Attendance records
- Payment and finance tracking
- Monthly reports
- Backup and restore

## Project Structure

```text
lib/
  core/           shared constants, theme, and helpers
  data/           models, repositories, and database
  presentation/   screens and reusable widgets
```

## Requirements

1. Flutter SDK 3.x or newer
2. Android Studio or VS Code

## Run

```bash
flutter pub get
flutter run
```

## APK

The current APK is included in this repository:

`releases/TennisApp-release.apk`

## Business Rules

- Makeup sessions are free and reduce coach debt
- Group-fee absence does not remove the fee
- Payments can be split into multiple entries
- Ball costs are tracked separately
- Coach history is preserved

## Notes

- The repository currently includes design and architecture notes used during development.
- The APK is large enough that future releases may be better handled through GitHub Releases rather than normal repository history.

## Owner

Ashkan Mardanpour
