# `lib/lib/` Legacy Tree Audit

Audited 2026-09-20 on `main` commit `11c7039`.

## Inventory

| Finding | Count |
| --- | ---: |
| Files under `lib/lib/` | 61 |
| Byte-identical counterparts under `lib/` | 47 |
| Diverged counterparts | 14 |
| Missing counterparts | 0 |
| Current imports referencing nested paths | 0 found |

## Classification

- **IDENTICAL DUPLICATE:** 47 files match the active `lib/` path byte-for-byte.
- **DIVERGED LEGACY:** 14 files have a counterpart with different content. Differences include repository/database behavior and older application wiring; they cannot be removed by assuming equivalence.
- **ACTIVELY USED:** No active `lib/main.dart`, test, Android, or CI reference resolving into `lib/lib/` was found.
- **UNKNOWN:** Whether an external consumer, unpublished branch, or historical workflow depends on the nested tree cannot be proven from the current repository.

## Decision

Keep `lib/lib/` for now. Before removal, validate a temporary copy with the directory absent using `flutter analyze`, `flutter test`, debug build, and release build. If all pass, remove it in a dedicated commit and retain this audit as the rationale. No source behavior was changed for this documentation audit.
