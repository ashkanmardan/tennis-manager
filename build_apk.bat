@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter is not on PATH. Install Flutter and run flutter doctor first.
  exit /b 1
)

call flutter pub get
if errorlevel 1 exit /b 1

call flutter build apk --debug
if errorlevel 1 exit /b 1

echo Debug APK: %CD%\build\app\outputs\flutter-apk\app-debug.apk
echo For a public release, follow docs\RELEASING.md and configure private signing.
