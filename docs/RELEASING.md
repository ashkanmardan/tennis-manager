# Releasing

Release `v1.0.1` was prepared manually from commit `ff160e7`. No automatic public release signing is configured because the production keystore must remain private and GitHub Actions signing secrets have not been provisioned.

1. Review the diff, asset provenance, privacy behavior, and open audit findings.
2. Update `pubspec.yaml` version and `CHANGELOG.md` with verified changes.
3. Run `flutter pub get`, `flutter analyze`, `flutter test`, and a real Android install/upgrade test.
4. Configure a private Android release keystore outside Git. Supply `keyAlias`, `keyPassword`, `storeFile`, and `storePassword` through a local ignored `android/key.properties`; `storeFile` may be an absolute path outside the repository (use forward slashes on Windows). Never commit the keystore or passwords. Verify the output's signature and package/version before distributing it. The maintainer's existing key was reused for `v1.0.1`; do not replace or delete it.
5. Run `flutter build apk --release` and inspect the resulting `build/app/outputs/flutter-apk/app-release.apk`.
6. Tag the exact reviewed commit (for example, `vX.Y.Z`) only after the version and build match.
7. Create a GitHub Release from that tag, attach the verified signed APK, and publish release notes based on the changelog.

Future release automation can be added after GitHub secrets are deliberately provisioned. Required secret names would be `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, and `ANDROID_STORE_PASSWORD`; secret values must never be committed or printed. Do not commit new APKs to normal source history. The existing `releases/TennisApp-release.apk` remains historical material and is not a current download.

## Local signing setup

Generate a new key only when no existing production key is available:

```powershell
keytool -genkeypair -v -keystore tennis-manager-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias tennis-manager
```

Keep the keystore and passwords in an encrypted backup. Create ignored `android/key.properties` with the four required properties, then build with `flutter build apk --release`. Verify the result without exposing secret values:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
flutter build apk --release --no-pub
apksigner verify --verbose build\app\outputs\flutter-apk\app-release.apk
aapt dump badging build\app\outputs\flutter-apk\app-release.apk
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
```

Losing the signing key can prevent updates to users who already installed the app. Never rotate it casually.
