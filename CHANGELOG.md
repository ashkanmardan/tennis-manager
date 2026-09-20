# Changelog

All notable changes from this point forward will be documented here, following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Earlier release details have not been reconstructed.

## [Unreleased]

Future changes will be recorded here.

## [1.0.1] - 2026-09-20

### Fixed

- Finish initial setup through the app's existing state routing instead of navigating to an undefined `/home` route.
- Save the player, initial package, and generated sessions together in one transaction. Failed setup keeps the entered information and allows retrying without duplicate records.

### Added

- Open source documentation, contribution and security policies, issue forms, and CI validation.
- A focused test for payment amount formatting and parsing.
- Widget tests with SQLite for successful setup and recovery from a failed session write.
