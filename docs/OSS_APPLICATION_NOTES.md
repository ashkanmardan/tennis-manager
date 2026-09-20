# Reusable application notes

**Project:** Tennis Manager

**URL:** <https://github.com/ashkanmardan/tennis-manager>

**Maintainer:** Ashkan Mardanpour
**License:** MIT for original project code, documentation, and maintainer-designed launcher icons; bundled Vazirmatn font is SIL OFL 1.1.

**Description:** A Persian-first Flutter Android app for tracking a tennis player's training packages, sessions, payments, and coach information. The interface uses RTL layout and Jalali dates. Data is stored in local SQLite, and the app can export a shareable JSON backup. Public source lets users inspect how their personal training data is handled and lets contributors improve the Persian/RTL workflow.

**Stack:** Flutter/Dart, Android/Kotlin host, SQLite via `sqflite`, `shamsi_date`, Provider. The original public history contains four commits at the audit point. The published draft PR adds contributor documentation and CI; its [first validation run](https://github.com/ashkanmardan/tennis-manager/actions/runs/35475491390) passed. The roadmap prioritizes reproducible builds, meaningful data/backup tests, and verified releases.

**Contribution model:** Issues for bugs/features and pull requests against `main`, with a contribution guide, code of conduct, and private security reporting policy. There are no claimed external contributors or adoption metrics.

Before any application, update this text with the actual merged commit, observed CI run, release URL, maintainer contact, and only metrics supported by GitHub or other first-party evidence. Do not infer adoption from a public repository.
