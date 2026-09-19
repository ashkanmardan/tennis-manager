# Open source audit

Audited 2026-09-20 from `main` at `a721d01` (four commits), before the readiness branch. Findings describe observed source and local checks; they do not certify the old APK.

## Inventory

- Flutter/Dart Android app: `lib/main.dart`, `lib/app.dart`, `lib/core/`, `lib/data/`, `lib/presentation/`. With the inspected Flutter 3.47.1 SDK, Android Gradle defaults are min API 24, target API 36, and compile API 36.
- Android host: Groovy Gradle files, manifest, Kotlin activity, launcher icons. Initial clone lacked the Gradle wrapper. `pubspec.yaml` declares Dart `>=3.0.0 <4.0.0`, app version `1.0.0+1`, Flutter and `flutter_localizations` from the SDK, and `sqflite`, `path`, `provider`, `shamsi_date`, `path_provider`, `cupertino_icons`, `url_launcher`, `image_picker`, and `share_plus`. Dev dependencies: `flutter_test`, `flutter_lints`.
- Original CI: one `build.yml`, push/manual only, Flutter 3.22.0, Java 17. It built a temporary generated scaffold, downloaded font files at runtime, and uploaded an APK artifact. It did not analyze or test pull requests. This branch replaces it with validation for pushes and PRs, tracked fonts, and a Gradle wrapper.
- Original tests: none. A small amount-formatting test is added. The pre-change `flutter analyze` passed locally with Flutter 3.47.1; pre-change `flutter test` failed because `test/` did not exist. `dart format --output=none --set-exit-if-changed lib` reported 67 files needing formatting.
- Resolved direct pub package licenses were inspected in the local package cache: `sqflite`, `path`, `shamsi_date`, `path_provider`, `url_launcher`, `image_picker`, and `share_plus` carry BSD-style notices; `provider` and `cupertino_icons` carry MIT notices. This is not a full transitive or release-binary license audit.
- Binary assets: `releases/TennisApp-release.apk` is 56,692,883 bytes. `aapt` reports package `com.ashkan.tennis_manager`, version `1.0.0` (code 1), min API 24 and target API 36. `apksigner verify` passed with one v2 signer; signer identity and source revision were not matched. There are bundled Vazirmatn TTF/WOFF2 files and generated-looking launcher PNGs. `assets/images/` contains no screenshot. No lockfile was tracked initially.
- Documentation: README, design/architecture drafts, `GAP_ANALYSIS.md`, `SETUP_GITHUB.md`; no license, contribution policy, conduct policy, security policy, changelog, roadmap, issue forms, or PR template at the audit start.

## Findings by severity

### Critical

- None confirmed. No tracked keystore, `key.properties`, `.env`, or obvious literal credential was found in the current tracked text scan. This does not audit all historical blobs or establish that the old APK is safe.

### High

- **Release provenance/signing unresolved.** The APK is committed to source history and has no verified source commit or GitHub Release. Its signature structure validates, but the signer has not been matched to a maintainer-controlled release key. The public Gradle file expects private signing properties. Do not present it as a new verified release.
- **Incomplete Android build scaffold.** A fresh clone lacked a Gradle wrapper. The older workflow worked around this by generating a project; local build exposed outdated Gradle/AGP versions. This branch adds a wrapper and updates build tooling; verify on GitHub Actions and an Android device.
- **Stale generated plugin registrant.** A tracked `GeneratedPluginRegistrant.java` referenced an obsolete `path_provider` Android class and broke a local debug build. It has been removed from version control; Flutter generates it during builds.
- **Sensitive backup content.** JSON backups include personal/coach/payment data and can be shared to other apps. No app-level encryption is apparent. The backup is a selected-data export, not a proven complete migration archive.

### Medium

- **Duplicated tree.** `lib/lib/` contains 61 files: 47 matched active paths byte-for-byte at audit time, while 14 differed or had no counterpart. It may confuse contributors and complicate analysis; removal needs owner review because historical code differs.
- **Asset provenance.** Vazirmatn is SIL OFL 1.1; its license notice is now included. Icon scripts indicate local generation/copy steps, but the exact provenance of checked-in launcher images and full source ownership should be confirmed by the maintainer before a release. The MIT license covers original project code/docs and does not override third-party licenses.
- **Product description drift.** The source entry point and SQLite schema focus on one player, packages, sessions, and payments. Historic drafts describe broader student/coach management; documentation now distinguishes implemented behavior from proposals.
- **Security contact gap.** No dedicated private email was provided. GitHub private vulnerability reporting was enabled on 2026-09-20, but has not been tested from an external reporter account. The conduct policy still needs a dedicated private channel.
- **No test coverage for migrations, restore, payments, or session state.** The added number-formatting test only covers a small pure helper.

### Low

- Existing Dart formatting differs from `dart format`; a repository-wide format pass would obscure functional history. Format changed Dart files and plan a dedicated cleanup.
- `SETUP_GITHUB.md`, icon scripts, and sync scripts contain machine-specific or obsolete paths and remain for owner review. The Windows `build_apk.bat` helper was corrected on this branch to build a debug APK; use the new installation/release docs for current instructions.
- `pubspec.lock` was ignored; this branch tracks it for reproducible app dependency resolution.

### Optional

- Capture real redacted screenshots, improve report/export design, and revisit backup formats per historic design notes.

## Security and licensing scope

The current manifest requests storage/media permissions. No analytics SDK or app-owned server endpoint appeared in the inspected active source. External sharing and Instagram links can leave the app. Review the [privacy description](PRIVACY.md). The static secret scan found signing property names but no values; historical Git content, transitive packages, native merged manifests, and the old APK still require separate review.

CodeQL does not analyze Dart, the primary language here; a token CodeQL workflow for the small Android host would not provide meaningful Dart coverage. Dependabot and Flutter analysis are more relevant now. GitHub's [supported CodeQL languages](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-code-scanning) include Java/Kotlin but not Dart.
