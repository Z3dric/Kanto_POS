Steps to build APK (debug and signed release)

1) Prepare Flutter environment

- Ensure Flutter, Android SDK, and JDK are installed and `flutter doctor` is clean.

2) Fast debug APK (no signing)

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

3) Generate a keystore (if you don't have one)

```powershell
keytool -genkey -v -keystore C:\Users\YOU\key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias YOUR_KEY_ALIAS
```

4) Create `android/key.properties` from `android/key.properties.template` and fill values. Example:

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=C:\\Users\\YOU\\key.jks
```

5) Build signed release APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

6) (Optional) Build app bundle for Play Store

```powershell
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Notes:
- `android/key.properties` is ignored by git by default; do not commit it.
- If you need, I can also help generate the keystore here as a downloadable file, but for security you may prefer creating it locally.
