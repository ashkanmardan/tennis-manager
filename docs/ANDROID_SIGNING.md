# Android signing

The public repository contains only the Gradle wiring and ignored-file rules. The release keystore, `android/key.properties`, and all passwords stay on the maintainer's machine.

For `v1.0.1`, the maintainer's existing keystore was reused. Its certificate matched the historical APK and the new release APK, so Android can treat the new build as an update. The public certificate SHA-256 fingerprint is recorded in the release readiness report; private key material is not.

Use `docs/RELEASING.md` for setup and verification commands. Back up the keystore securely and keep the alias and passwords with it. A new keystore must not be generated over an existing production identity.
