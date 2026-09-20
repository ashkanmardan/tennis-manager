# Device Test Report

## Test metadata

| Item | Value |
| --- | --- |
| App version | v1.0.1 (version code 2) |
| APK SHA-256 | `F2E91BF830A9B47A649B24CE6E6AE62C19F9CDC818161660F58D54C6390F3C95` |
| Test date | 2026-09-20 |
| Device model | Not recorded |
| Android version | Not recorded |

The maintainer reported that the release APK installed and onboarding completed on a real Android phone. The evidence supplied for this audit is one home dashboard screenshot; it does not identify the device or Android version. The table therefore does not upgrade unobserved flows to PASS.

| Feature | Device | Android | Result | Notes |
| --- | --- | --- | --- | --- |
| Fresh install | Unrecorded real phone | Unrecorded | PARTIAL | Installation was reported; exact device metadata is missing. |
| First launch / onboarding | Unrecorded real phone | Unrecorded | PARTIAL | Maintainer reported successful onboarding. |
| Profile creation | Unrecorded real phone | Unrecorded | NOT TESTED | No structured evidence supplied. |
| Package creation / session generation | Unrecorded real phone | Unrecorded | NOT TESTED | Not independently verified. |
| Session editing / attendance | Unrecorded real phone | Unrecorded | NOT TESTED | Not independently verified. |
| Payment entry / reports | Unrecorded real phone | Unrecorded | NOT TESTED | Not independently verified. |
| Persian RTL / Jalali dates | Unrecorded real phone | Unrecorded | PARTIAL | Visible in the supplied dashboard screenshot; full screen coverage is not claimed. |
| Restart / persistence | Unrecorded real phone | Unrecorded | NOT TESTED | Not independently verified. |
| Backup export / restore | Unrecorded real phone | Unrecorded | NOT TESTED | Requires a structured synthetic-data test. |
| External links / image picker / permissions | Unrecorded real phone | Unrecorded | NOT TESTED | Not independently verified. |
| Error handling | Unrecorded real phone | Unrecorded | PARTIAL | Onboarding failure/retry is covered by automated widget tests; device behavior is not. |
| Upgrade from older version | Unrecorded real phone | Unrecorded | NOT TESTED | No upgrade test evidence. |

## Screenshot evidence

`docs/screenshots/01-dashboard.jpg` is the supplied real dashboard screenshot. It is documentation evidence, not a substitute for the missing device metadata or feature matrix.
