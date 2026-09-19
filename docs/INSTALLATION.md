# Installation

1. Install Flutter 3.47.1 and complete `flutter doctor` setup for Android.
2. Install JDK 21 and Android SDK API 36. Accept required Android licenses with `flutter doctor --android-licenses`.
3. Clone the repository and run `flutter pub get`.
4. Connect an Android device or start an emulator, check `flutter devices`, then run `flutter run`.

To create a local development APK, run `flutter build apk --debug`; the output is normally `build/app/outputs/flutter-apk/app-debug.apk`. A debug APK is for testing and uses a debug key. It is not a public release. See [releasing](RELEASING.md) for signed release requirements.

The repository now includes its Android Gradle wrapper. If Flutter rewrites Android project files, review the diff before committing. The older `build_apk.bat` assumes a machine-specific Flutter path and prints an outdated APK path; use the commands above.
