# Testing

Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` from the repository root. `test/number_formatter_test.dart` covers deterministic display/parse behavior for amounts. CI also checks formatting for new tests and builds a debug APK. Existing application Dart files have formatting differences, so enforcing `dart format .` across all source would create a large unrelated diff.

Important untested paths are database migrations, backup restore validation, package and session transitions, debt/payment calculations, and device-level permission behavior. Add focused tests with realistic edge cases when working in those areas. A green unit test suite alone does not establish release readiness; test install, upgrade, backup, and restore on an Android device before publishing an APK.
