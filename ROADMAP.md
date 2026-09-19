# Roadmap

This is a direction, not a release commitment. Please open an issue before starting a large item.

## Planned

- Make the Android project reproducible from a clean clone, with a tracked Gradle wrapper and verified signing path.
- Add meaningful tests for backup restore, database migrations, payment calculations, and session state.
- Confirm asset provenance and provide a private security reporting channel.

## Under consideration

- Distinct lightweight and full backup formats, including media, as described in the historical design notes.
- Report export and stronger report filtering, subject to validation of existing behavior.
- Accessibility and localization improvements after real device testing.

## Completed in the current codebase

- Persian RTL interface and Jalali date helpers.
- Local SQLite persistence with sessions, packages, payments, and a JSON backup/share screen.

The older design documents are proposals, not a guarantee that every described feature is implemented. See [architecture](docs/ARCHITECTURE.md) and [audit](docs/OPEN_SOURCE_AUDIT.md).
