# Release Readiness Report

## Version

`1.0.1+2`, published as tag `v1.0.1` from `ff160e7decb7eb3bcddb4ba12eac4188b3d4443b`.

## Build and tests

- `flutter pub get`: passed.
- `dart format --output=none --set-exit-if-changed test`: passed.
- `flutter analyze --no-pub`: passed with no issues.
- `flutter test --no-pub`: 4 tests passed.
- `flutter build apk --release --no-pub`: passed.
- GitHub Flutter CI on the merged commit: passed.

## APK verification

The release APK reports package `com.ashkan.tennis_manager`, version `1.0.1`, version code `2`, compile API 36, and a valid aligned signature. The certificate SHA-256 fingerprint is `d1b14d3ab5785a546838e0ef5654f47c319def4b03389f4b5142724e4600299c`.

APK SHA-256:

`F2E91BF830A9B47A649B24CE6E6AE62C19F9CDC818161660F58D54C6390F3C95`

## Device test status

The maintainer tested the release APK on a real Android phone and confirmed the onboarding completion flow works. A full release matrix for backup/restore, permissions, external links, and upgrade behavior is not claimed.

## Screenshots

No real screenshots were available in this release preparation. None were fabricated.

## GitHub Release and tag

The release is published as GitHub Release `v1.0.1` with `TennisManager-v1.0.1.apk` and `SHA256SUMS.txt`.

## Security review

No signing files, passwords, private keys, `.env` files, or GitHub secret values are committed. Signing is manual and uses the maintainer's existing key. The old APK remains historical only.

## Remaining risks and manual tasks

- Keep multiple encrypted backups of the signing keystore.
- Test private vulnerability reporting from an external account.
- Add real redacted screenshots in a later change.
- Review and remove `lib/lib` only in a separate change after another import/history audit.
- Add GitHub signing secrets only after deliberate secret-management setup; do not print or upload them.

## OSS program readiness

The repository now has a verified public Android release and passing CI. This does not imply approval by JetBrains, BrowserStack, Snyk, or any other program.
