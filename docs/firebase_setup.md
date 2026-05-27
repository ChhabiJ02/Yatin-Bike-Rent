# Firebase setup for Yatin Bike Rent

This project uses `firebase_core`, `firebase_auth`, and `cloud_firestore`.

To connect the app to the Firebase project named `yatin-bike-rent`: 

1. Install FlutterFire CLI (if not installed):

```bash
dart pub global activate flutterfire_cli
```

2. From the repository root, configure FlutterFire:

```bash
flutterfire configure --project=yatin-bike-rent
```

This will generate `lib/firebase_options.dart` with platform-specific `FirebaseOptions` and update platform projects.

3. Add platform files if needed (Android `google-services.json`, iOS `GoogleService-Info.plist`) — `flutterfire configure` generally handles this.

4. In the Firebase console for `yatin-bike-rent` enable Authentication (Email/Password) and Firestore.

5. Run `flutter pub get`:

```bash
flutter pub get
```

6. Run the app:

```bash
flutter run
```

Notes:
- If you prefer to add credentials manually, place `google-services.json` under `android/app/` and `GoogleService-Info.plist` under `ios/Runner/`.
- Update Firestore rules to allow authenticated users as needed.
- The app expects `users`, `bikes`, `bookings`, and `challans` collections in Firestore. Create indexes/rules accordingly.

If you want, I can run `flutterfire configure` here if you provide access tokens, or guide you step-by-step while you run the commands locally.