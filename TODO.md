## TODO - Native splash + app logo integration

- [x] Update `android/app/src/main/res/drawable/launch_background.xml` (and `drawable-v21`) to show `assets/logos/png/logo1.png`-based launch background
- [ ] Update `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml` if required for launch theme consistency
- [ ] Update Android app icon resources (mipmap/ic_launcher.png variants) to match the logo
- [ ] Update iOS app icon set (`ios/Runner/Assets.xcassets/AppIcon.appiconset/*`) to match the logo
- [ ] Update iOS launch screen (`ios/Runner/Base.lproj/LaunchScreen.storyboard`) to use the logo
- [x] Keep Flutter animated splash as-is (already uses `assets/logos/png/logo1.png`)
- [ ] Run `flutter clean` (cmd below)
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` and verify:
  - OS-level launch screen shows the logo immediately
  - Flutter animated splash still animates
  - Navigation to `LoginScreen` works

