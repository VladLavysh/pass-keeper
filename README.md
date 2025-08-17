# test_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# Pass Keeper

Lightweight, offline-first password manager built with Flutter.

## Overview

Pass Keeper securely stores, searches, and manages passwords across platforms (Android, iOS, Web, Desktop). It includes a lock screen with passphrase (and optional biometrics), quick search, grouping, and JSON import/export with encrypted envelope detection.

- __Tech__: Flutter (Dart), Material Design dark theme
- __Targets__: Android, iOS, Web, Windows, macOS, Linux

## Features

- __Secure lock screen__ with passphrase and optional biometrics
  - See `lib/screens/lock_screen.dart` and biometric permissions in `android/app/src/main/AndroidManifest.xml`
- __Password storage__ with grouping and quick search by login
  - See `lib/screens/home_screen.dart`, `lib/components/password_list.dart`
- __Add/Edit passwords__ with inline validation, password generator, and a clear-form action for new entries
  - See `lib/screens/password_screen.dart`, `lib/components/input.dart`
- __Import/Export JSON__
  - Import plaintext JSON or detect an encrypted envelope (`cipher` + `ciphertext`)
  - Export current data to JSON
- __Local crypto helper__ for encryption/decryption primitives
  - See `lib/helpers/crypto_helper.dart`

## Project structure

- `lib/main.dart` – App entry and routes (`/`, `/lock`, `/add`, `/edit`)
- `lib/screens/` – Screens: `home_screen.dart`, `password_screen.dart`, `lock_screen.dart`
- `lib/components/` – Widgets: `input.dart`, `password_list.dart`
- `lib/models/` – Data models: `password_model.dart`, `password_group_model.dart`
- `lib/helpers/` – Utilities: `constants.dart`, `crypto_helper.dart`

## Getting started

Prerequisites:
- Flutter SDK installed and configured
- Dart SDK (bundled with Flutter)

Install dependencies:
```bash
flutter pub get
```

Run the app:
```bash
flutter run
```

Build release APK (Android):
```bash
flutter build apk --release
```

Other platforms:
```bash
# iOS (requires Xcode/macOS)
flutter build ios --release

# Web
flutter build web

# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## App icons

Configured via `flutter_launcher_icons`:
- Config: `pubspec.yaml` under `flutter_icons`
- Source: `assets/icon/app_icon.png`

Generate icons:
```bash
flutter pub run flutter_launcher_icons:main
```

## Import/Export format

- __Unencrypted JSON__: human-readable data for portability.
- __Encrypted envelope__: objects with `cipher` and `ciphertext`; decryption handled by `crypto_helper.dart`. Provide the passphrase on the lock screen.

## Security notes

- __Offline-first__: No cloud sync by default; data stays on-device.
- __Biometrics__: Android permissions present; availability depends on device/OS.
- __Encryption__: Review `lib/helpers/crypto_helper.dart` for algorithms and key derivation. Use a strong passphrase.
- __Backups__: Treat exported plaintext JSON as sensitive. Prefer encrypted exports when possible.

## Theming

Dark theme configured in `lib/main.dart` using `ThemeData.dark()` with custom colors.

## Roadmap ideas

- Cloud/secure sync option
- Per-field copy actions and masking toggles
- Enhanced password generator with policies
- Encrypted export by default with versioned schemas

## Contributing

Issues and PRs are welcome. Run `flutter analyze` and ensure builds succeed for your target platforms before submitting.

## License

Add your preferred license (e.g., MIT, Apache-2.0).
