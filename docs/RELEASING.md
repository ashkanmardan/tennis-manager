# Releasing

No automatic public release is configured. The application version is declared in `pubspec.yaml`, but that alone does not prove an APK was built from this revision or signed for distribution.

1. Review the diff, asset provenance, privacy behavior, and open audit findings.
2. Update `pubspec.yaml` version and `CHANGELOG.md` with verified changes.
3. Run `flutter pub get`, `flutter analyze`, `flutter test`, and a real Android install/upgrade test.
4. Configure a private Android release keystore outside Git. Supply `keyAlias`, `keyPassword`, `storeFile`, and `storePassword` through a local ignored `android/key.properties`; `storeFile` may be an absolute path outside the repository (use forward slashes on Windows). Never commit the keystore or passwords. Verify the output's signature and package/version before distributing it.
5. Run `flutter build apk --release` and inspect the resulting `build/app/outputs/flutter-apk/app-release.apk`.
6. Tag the exact reviewed commit (for example, `vX.Y.Z`) only after the version and build match.
7. Create a GitHub Release from that tag, attach the verified signed APK, and publish release notes based on the changelog.

Future release automation can be added once signing, upgrade compatibility, and artifact verification are established. Do not commit new APKs to normal source history. The existing `releases/TennisApp-release.apk` remains as historical material; its APK signature verifies, but its signer identity and source provenance are not established here.
