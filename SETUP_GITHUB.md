# راهنمای قدیمی (آرشیوی)

این فایل دستورهای اولیهٔ ساخت مخزن را ثبت می‌کند و مسیرها و روش دریافت APK آن دیگر معتبر نیستند. برای نصب از سورس، [راهنمای نصب](docs/INSTALLATION.md) و برای انتشار APK، [راهنمای انتشار](docs/RELEASING.md) را بخوانید.

# راهنمای گرفتن APK از GitHub

## مرحله ۱ — ساخت حساب GitHub (اگه نداری)

به https://github.com برو و ثبت‌نام کن.

## مرحله ۲ — ساخت Repository جدید

1. به https://github.com/new برو
2. نام: `tennis-manager`
3. Private ✅ (اگه نمی‌خوای عمومی باشه)
4. **هیچ‌چیزی tick نزن** (نه README، نه gitignore)
5. Create repository کلیک کن

## مرحله ۳ — نصب Git روی ویندوز

از https://git-scm.com/download/win دانلود و نصب کن.

## مرحله ۴ — push کردن کد

ترمینال (CMD یا PowerShell) باز کن و این دستورها رو بزن:

```bash
cd "C:\Users\Ashkan\Claude\Projects\اپ اندروید"

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/tennis-manager.git
git push -u origin main
```

> جای `YOUR_USERNAME` نام کاربری GitHub خودت رو بذار

## مرحله ۵ — دانلود APK

بعد از push، GitHub شروع به build می‌کنه:

1. به صفحه repository برو
2. تب **Actions** رو کلیک کن
3. روی آخرین workflow کلیک کن
4. صبر کن تا ✅ سبز بشه (حدود ۱۰-۱۵ دقیقه)
5. پایین صفحه، بخش **Artifacts** — فایل `tennis-manager-apk` رو دانلود کن
6. zip رو باز کن — فایل `app-release.apk` رو روی گوشی نصب کن

## نصب APK روی گوشی

1. فایل را به گوشی منتقل کن (USB یا Telegram)
2. در تنظیمات گوشی: **نصب از منابع ناشناس** را فعال کن
3. فایل apk را باز کن و نصب کن

---
ساخته شده توسط Claude برای اشکان مردانپور
