# Nice — Tenant Billing App

**Nice** is a simple, convenient tenant billing app that I made specially for my mother, to help her track her tenants' bills. Instead of writing everything down on paper and computing totals by hand, she can now record meter readings, generate bills, and share receipts — all from her phone.

Made with ❤️ for Mama.

## What it does

- **Manage tenants** — keep a list of tenants and view each one's billing history.
- **Monthly bills** — record each tenant's bill for the month, including:
  - **Electricity** — computed automatically from meter readings (current − previous reading × rate per kWh, so no manual math needed).
  - **Water** and **WiFi** charges.
  - **Extra charges** — add custom items like rent.
- **Automatic due dates** — every bill is due 10 days after it's created, and the app reminds you about unpaid bills.
- **Receipts** — generate a clean receipt for any bill and share it with the tenant (via Messenger, SMS, etc.).
- **Calendar** — see bills on a calendar and add your own notes for any date.
- **Notifications** — get notified about unpaid bills and reminders.
- **Cloud sync** — all data is saved securely in the cloud (Firebase), so nothing is lost even if the phone is changed.

## Tech stack

- [Flutter](https://flutter.dev/) (Dart)
- [Firebase](https://firebase.google.com/) — Authentication & Cloud Firestore

## How to install

### Option 1: Install the app on an Android phone (for everyday use)

1. Build the APK (or use one that's already been built):
   ```
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
2. Copy the APK to the phone (via USB, Google Drive, or Messenger).
3. On the phone, tap the APK file to install it. If asked, allow **"Install from unknown sources."**
4. Open **Nice**, sign in, and start adding tenants and bills!

### Option 2: Run from source code (for developers)

**Requirements:**
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x or newer
- Android Studio or VS Code with the Flutter extension
- A connected device or emulator

**Steps:**

1. Clone or download this project, then open a terminal in the project folder:
   ```
   cd nice_app
   ```
2. Install the dependencies:
   ```
   flutter pub get
   ```
3. Run the app:
   ```
   flutter run
   ```

> **Note:** The app uses Firebase. The project already includes its Firebase configuration (`lib/firebase_options.dart`), so it should work out of the box. If you fork this project for your own use, set up your own Firebase project with [FlutterFire](https://firebase.google.com/docs/flutter/setup) (`flutterfire configure`).

## About

This app was made with love as a personal project — to make my mother's life as a landlord easier and more convenient. 🏠
