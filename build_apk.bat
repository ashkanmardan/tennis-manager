@echo off
setlocal

cd /d %~dp0

set "FLUTTER_ROOT=C:\Users\Ashkan\develop\flutter"
if not exist "%FLUTTER_ROOT%\bin\flutter.bat" (
  echo Flutter SDK not found at %FLUTTER_ROOT%
  exit /b 1
)

echo Running pub get...
"%FLUTTER_ROOT%\bin\flutter.bat" pub get
if errorlevel 1 exit /b 1

echo Building APK...
"%FLUTTER_ROOT%\bin\flutter.bat" build apk --release
if errorlevel 1 exit /b 1

echo.
echo Done! APK at: C:\TennisApp\build\app\outputs\flutter-apk\app-release.apk
pause
