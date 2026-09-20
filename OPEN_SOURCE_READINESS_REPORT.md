# Open Source Readiness Report

## Executive Summary

Prepared on branch `chore/open-source-readiness` from `a721d01` on 2026-09-20. This branch improves licensing, contributor guidance, privacy documentation, Android build reproducibility, tests, and CI. The project remains an early public Android app; no external adoption or release history is claimed.

## Changes Made

- Rewrote README and added audit, installation, architecture, testing, privacy, release, program-readiness, and application notes.
- Added MIT license for original project material, SIL OFL font notice/license, Contributor Covenant 3.0, contribution/security policies, changelog, roadmap, issue forms, PR template, Dependabot, and a Flutter CI workflow.
- Added a small amount-formatting test, tracked `pubspec.lock` and Android Gradle wrapper, updated Android build tooling, and removed a stale generated plugin registrant from version control.
- Updated the Windows debug-build helper and marked the old GitHub setup guide as archival. Retained historic design documents and the old APK.

## Legal / License Status

MIT is in the root `LICENSE` for original project code, documentation, and launcher icon artwork. The maintainer confirmed on 2026-09-20 that they developed the app and designed the icons; the ten checked-in launcher PNGs matched the clean local source checkout. Vazirmatn is SIL OFL 1.1 (`assets/fonts/OFL.txt`); Contributor Covenant 3.0 text is CC BY-SA 4.0. Direct pub package license files showed permissive MIT/BSD-style terms. Transitive/native components and the old APK were not fully audited.

## Security Status

No obvious tracked credential, private key, keystore, `.env`, or historical sensitive filename was found. The public Gradle file contains signing property names, not values. JSON backups can include personal and payment information and may be sent through Android sharing. GitHub private vulnerability reporting, dependency graph, Dependabot alerts, malware alerts, security updates, and grouped security updates were enabled on 2026-09-20. The private report path still needs an external reporter test. The old APK has a valid v2 APK signature, but the signer identity has not been matched to the owner.

## CI Status

The new `.github/workflows/flutter-ci.yml` runs on pull requests and pushes to `main`: dependency resolution, test formatting, analysis, tests, and Android debug build. The [first GitHub Actions run](https://github.com/ashkanmardan/tennis-manager/actions/runs/35475491390) on draft PR #1 **passed** on 2026-09-20 in 5m 46s, including the debug APK build. Build logs warn that the selected Gradle, AGP, and Kotlin versions will need future upgrades. Future commits require their own CI result; a badge on `main` reflects the merged branch only.

## Test Status

`flutter test --no-pub`: **passed, 2 tests**. `flutter analyze --no-pub`: **passed, no issues**. `dart format --output=none --set-exit-if-changed test`: **passed**. A full existing-source format check fails because 67 historical files need formatting; CI checks the new test tree only. Device-level and database/backup tests remain outstanding.

## Build Status

`flutter build apk --debug --no-pub`: **passed** with Flutter 3.47.1, Dart 3.13.1, JDK 21, Android API 36, Gradle 8.14.3, AGP 8.11.1, and Kotlin 2.2.20. The generated debug APK signature verifies and reports package `com.ashkan.tennis_manager`, version `1.0.0` (code 1), min API 24, target API 36. `flutter build apk --release --no-pub`: **failed** at `:app:packageRelease` because signing config `release` has no private `storeFile`; no release APK was produced. No Android device or emulator was connected, so installation and runtime are unverified.

## Documentation Status

User, contributor, privacy, testing, architecture, and release documentation is present. No real screenshots exist yet. Historic drafts remain available but may differ from current behavior.

## Release Status

No verified GitHub Release exists. The old tracked APK is version 1.0.0 and its signature validates, but source provenance and signer ownership are unconfirmed. Public release automation was deferred until private signing and upgrade tests are established. New APKs should be attached to GitHub Releases rather than committed to source history.

## GitHub Community Health

README, license, conduct, contributing, security policy, issue forms, and PR template are present on the published draft PR branch. The first PR CI run passed. Repository description and nine topics were updated to reflect implemented features. GitHub's community health display for the default branch will reflect the new files after merge.

## Remaining Manual Tasks

1. Review the old APK's signer against the intended release key; do not present that historical binary as a verified release.
2. Test GitHub private vulnerability reporting from an external reporter account and choose a private conduct-reporting contact.
3. Install the app on Android, test upgrade and backup/restore with synthetic data, and capture redacted real screenshots. Recheck CI after subsequent commits and before merge.
4. Configure a private release key outside Git, verify a signed release APK, then create a tag and GitHub Release.
5. Review the divergent `lib/lib/` tree, obsolete local scripts, transitive licenses, and future Gradle/AGP/Kotlin compatibility in focused follow-up changes.

## Recommended Programs to Apply For Now

Normal free developer plans such as Snyk Free and JetBrains's individual non-commercial use can be evaluated under the provider's current terms. This does not imply acceptance or special OSS sponsorship. See [program readiness](docs/OPEN_SOURCE_PROGRAM_READINESS.md).

## Programs to Apply For Later

Wait on established-project JetBrains support and BrowserStack until a verified release, CI record, and sustained development are visible. Netlify needs an actual project site; Docker Sponsored OSS needs a genuine container distribution use case. PVS-Studio suitability for Dart must be confirmed first.

## Risks / Concerns

The historical APK is large and has unresolved provenance; backups contain sensitive data; `lib/lib/` diverges from active source; Android build tooling currently works but Flutter warns that the selected Gradle/AGP/Kotlin versions will need future upgrades. The first PR CI run passed; device behavior is still unverified.

## Recommended Next Development Steps

Review the draft PR, validate installation/backup on a device, resolve release signing, then create the first verified GitHub Release. Add focused migration and backup tests before expanding features.
