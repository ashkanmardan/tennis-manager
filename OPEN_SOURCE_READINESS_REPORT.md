# Open Source Readiness Report

## Executive Summary

Prepared on branch `chore/open-source-readiness` from `a721d01` on 2026-09-20. This branch improves licensing, contributor guidance, privacy documentation, Android build reproducibility, tests, and CI. The project remains an early public Android app; no external adoption or release history is claimed.

## Changes Made

- Rewrote README and added audit, installation, architecture, testing, privacy, release, program-readiness, and application notes.
- Added MIT license for original project material, SIL OFL font notice/license, Contributor Covenant 3.0, contribution/security policies, changelog, roadmap, issue forms, PR template, Dependabot, and a Flutter CI workflow.
- Added a small amount-formatting test, tracked `pubspec.lock` and Android Gradle wrapper, updated Android build tooling, and removed a stale generated plugin registrant from version control.
- Updated the Windows debug-build helper and marked the old GitHub setup guide as archival. Retained historic design documents and the old APK.

## Legal / License Status

MIT is in the root `LICENSE` for original code/docs. Vazirmatn is SIL OFL 1.1 (`assets/fonts/OFL.txt`); Contributor Covenant 3.0 text is CC BY-SA 4.0. Direct pub package license files showed permissive MIT/BSD-style terms. The owner should confirm launcher icon and source provenance; transitive/native components and the old APK were not fully audited.

## Security Status

No obvious tracked credential, private key, keystore, `.env`, or historical sensitive filename was found. The public Gradle file contains signing property names, not values. JSON backups can include personal and payment information and may be sent through Android sharing. A private vulnerability-reporting channel still needs to be enabled and tested by the owner. The old APK has a valid v2 APK signature, but the signer identity has not been matched to the owner.

## CI Status

The new `.github/workflows/flutter-ci.yml` parses locally and is configured for pull requests and pushes to `main`: dependency resolution, test formatting, analysis, tests, and Android debug build. **GitHub Actions has not run this new workflow yet.** Its badge must be read from the real run after the branch is published and merged.

## Test Status

`flutter test --no-pub`: **passed, 2 tests**. `flutter analyze --no-pub`: **passed, no issues**. `dart format --output=none --set-exit-if-changed test`: **passed**. A full existing-source format check fails because 67 historical files need formatting; CI checks the new test tree only. Device-level and database/backup tests remain outstanding.

## Build Status

`flutter build apk --debug --no-pub`: **passed** with Flutter 3.47.1, Dart 3.13.1, JDK 21, Android API 36, Gradle 8.14.3, AGP 8.11.1, and Kotlin 2.2.20. The generated debug APK signature verifies and reports package `com.ashkan.tennis_manager`, version `1.0.0` (code 1), min API 24, target API 36. `flutter build apk --release --no-pub`: **failed** at `:app:packageRelease` because signing config `release` has no private `storeFile`; no release APK was produced. No Android device or emulator was connected, so installation and runtime are unverified.

## Documentation Status

User, contributor, privacy, testing, architecture, and release documentation is present. No real screenshots exist yet. Historic drafts remain available but may differ from current behavior.

## Release Status

No verified GitHub Release exists. The old tracked APK is version 1.0.0 and its signature validates, but source provenance and signer ownership are unconfirmed. Public release automation was deferred until private signing and upgrade tests are established. New APKs should be attached to GitHub Releases rather than committed to source history.

## GitHub Community Health

README, license, conduct, contributing, security policy, issue forms, and PR template are present on this branch. Community health on GitHub and CI results cannot be confirmed until the branch is published and the workflow runs.

## Remaining Manual Tasks

1. Confirm ownership/provenance of source and launcher icons, then review the old APK's signer against the intended release key.
2. Enable/test GitHub private vulnerability reporting and choose a private conduct-reporting contact.
3. Run CI on a PR, install the resulting app on Android, test upgrade and backup/restore with synthetic data, and capture redacted real screenshots.
4. Configure a private release key outside Git, verify a signed release APK, create a tag and GitHub Release, and set repository description/topics through GitHub settings if desired.
5. Review the divergent `lib/lib/` tree, obsolete local scripts, transitive licenses, and future Gradle/AGP/Kotlin compatibility in focused follow-up changes.

## Recommended Programs to Apply For Now

Normal free developer plans such as Snyk Free and JetBrains's individual non-commercial use can be evaluated under the provider's current terms. This does not imply acceptance or special OSS sponsorship. See [program readiness](docs/OPEN_SOURCE_PROGRAM_READINESS.md).

## Programs to Apply For Later

Wait on established-project JetBrains support and BrowserStack until a verified release, CI record, and sustained development are visible. Netlify needs an actual project site; Docker Sponsored OSS needs a genuine container distribution use case. PVS-Studio suitability for Dart must be confirmed first.

## Risks / Concerns

The historical APK is large and has unresolved provenance; backups contain sensitive data; `lib/lib/` diverges from active source; Android build tooling currently works but Flutter warns that the selected Gradle/AGP/Kotlin versions will need future upgrades. CI and device behavior are not yet proven.

## Recommended Next Development Steps

Publish the branch, review the first CI run, validate installation/backup on a device, resolve signing and asset provenance, then create the first verified GitHub Release. Add focused migration and backup tests before expanding features.
