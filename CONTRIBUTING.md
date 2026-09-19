# Contributing

Contributions to the Persian UI, documentation, tests, and Android build are welcome. Please discuss larger changes in an issue before implementation.

## Prerequisites

- Flutter 3.47.1 and its bundled Dart SDK (the version used by CI)
- Android SDK with API 36, and JDK 21 for Android builds
- Git and an Android device or emulator for UI work

The repository includes its Android Gradle wrapper. If Flutter proposes Android scaffold updates, review the generated changes before committing; see [installation notes](docs/INSTALLATION.md).

## Workflow

1. Fork the repository and clone your fork: `git clone https://github.com/YOUR_USERNAME/tennis-manager.git`.
2. Create a branch such as `fix/backup-validation`, `feat/report-export`, or `docs/install-guide`.
3. Run `flutter pub get`, then `flutter run` on a connected Android device.
4. Run `flutter analyze`, `flutter test`, and `dart format --output=none --set-exit-if-changed test` before opening a PR.
5. Open a focused pull request against `main`. Explain the problem, link the issue if one exists, list commands you actually ran, and attach real before/after images for UI changes. Describe any data or backup compatibility effect.

Use short, descriptive commits such as `fix: validate backup schema` or `docs: explain Android setup`. Do not include keys, personal data, generated build output, or APKs in commits. For Persian text, preserve RTL layout and test on an Android device. Update English documentation alongside behavior changes. Bug reports and feature requests have dedicated [issue forms](https://github.com/ashkanmardan/tennis-manager/issues/new/choose). Security issues should follow [SECURITY.md](SECURITY.md).
