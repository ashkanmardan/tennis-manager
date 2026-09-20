# Release audit

Audited 2026-09-20 against `main` commit `ff160e7decb7eb3bcddb4ba12eac4188b3d4443b`.

| Item | Verified state |
| --- | --- |
| Application version | `1.0.1+2` (`versionName 1.0.1`, `versionCode 2`) |
| Package | `com.ashkan.tennis_manager` |
| Minimum Android API | 24, from Flutter defaults used by this project |
| Target / compile API | target 36 / compile 36 |
| Gradle / Android plugins | Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20 |
| Signing | Existing private maintainer key, loaded from ignored `android/key.properties` |
| Public secrets | None committed; key files are ignored |
| Git tags/releases before this release | No tags and no GitHub Releases |
| CI | Flutter CI passed on merged commit `ff160e7` |
| Device test | Maintainer confirmed the onboarding flow and release APK work on a real Android phone; the full backup/upgrade matrix is not claimed |
| Screenshots | One supplied real dashboard screenshot committed under `docs/screenshots/01-dashboard.jpg`; no additional screenshots are claimed |
| Legacy APK | `releases/TennisApp-release.apk` is historical and excluded from current download instructions |
| Nested `lib/lib` | 61-file duplicate tree; no active import from the main entry point found, retained pending a separate cleanup review |

## Release blockers

No blocker remains for the manually verified Android APK release. Automated signing is intentionally not enabled because GitHub Actions signing secrets are not configured. Future release automation must fail closed when secrets are absent.

## Security notes

The signing identity is private. Backups exported by the app can contain profile and payment data and may be shared through Android's share sheet. Private vulnerability reporting still needs an external reporter test.
