# Final OSS Audit

Audited 2026-09-20 against `main` commit `11c7039` and the published `v1.0.1` release.

## Repository and release

- Repository: <https://github.com/ashkanmardan/tennis-manager>
- License: MIT for the project code and documentation; bundled Vazirmatn font remains under SIL OFL 1.1.
- Current release: `v1.0.1`, package `com.ashkan.tennis_manager`, version code `2`.
- Release assets: `TennisManager-v1.0.1.apk` and `SHA256SUMS.txt`.
- Latest `main` CI for `11c7039` passed: [run 35512037271](https://github.com/ashkanmardan/tennis-manager/actions/runs/35512037271).

## Verification state

- Local analysis and tests previously passed on the release source; the release PR CI passed.
- A real Android phone test was reported by the maintainer for installation and onboarding, but device model, Android version, and a full feature matrix were not recorded.
- Five real screenshots are now committed under `docs/screenshots/` for dashboard, finance, session form, sessions, and reports. Two profile screenshots were excluded because they expose phone and card numbers.
- Backup/restore, upgrade, permissions, external-link, picker, payment, report, and restart behavior remain untested in this audit.

## Source tree and technical debt

- `lib/lib/` contains 61 files: 47 byte-identical copies of active paths and 14 diverged copies. No import or entry-point reference to the nested tree was found.
- The nested tree is retained. Removal needs a dedicated temporary deletion validation and a separate cleanup commit.
- The historical `releases/TennisApp-release.apk` remains clearly labeled and is excluded from current download guidance.
- Historical design documents remain in the root because their links and value have not been fully mapped; they are not treated as current behavior.

## OSS program readiness

- BrowserStack: **POSSIBLE / APPLY WITH REALISTIC EXPECTATIONS** after recording a repeatable device matrix; one device result is not broad compatibility evidence.
- JetBrains established-project support: **WAIT FOR MORE MATURITY**; there is no evidence of external adoption or contributors.
- Snyk: **POSSIBLE / APPLY WITH REALISTIC EXPECTATIONS** for dependency review; do not claim Dart coverage without verifying it.
- Docker and Netlify: **NOT APPLICABLE NOW** for the current Android-only distribution.

## Remaining gaps

- Capture structured device QA with model and Android version.
- Add focused backup/restore and payment persistence tests.
- Revisit `lib/lib/` only after deletion validation.
- Test the private vulnerability-report path from an external account.
