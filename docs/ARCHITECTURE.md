# Architecture

`lib/main.dart` starts `TennisApp`. `lib/app.dart` configures `fa_IR`, RTL direction, the theme, and the `AppRepository` provider. `lib/presentation/` contains the screens. `lib/data/repositories/` provides data access. `lib/data/database/database_helper.dart` opens `tennis_player.db` through `sqflite` and declares schema version 3. `lib/core/` holds date, number, debt, and theme helpers.

The backup screen reads selected repository data, creates JSON in an app-specific external `backups` directory, and opens Android's share sheet. Inspect the current code before assuming it is a complete database export. The historical `FINAL_DESIGN*.md`, `ARCHITECTURE_AMENDMENTS_v3.0.md`, and `GAP_ANALYSIS.md` are useful context but contain proposed or stale statements. The `lib/lib/` tree contains an older parallel copy and is not imported by `lib/main.dart`; avoid changing it without a separate migration/removal review.
