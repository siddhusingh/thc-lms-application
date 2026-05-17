# THC-LMS Android Mobile App

Student/Participant-only Flutter Android app for the existing THC-LMS backend.

## What is included

- Android-only Flutter project with minimum SDK 29.
- Clean feature structure under `lib/features`.
- Provider state management.
- Dio API client with bearer token injection, refresh hook, and centralized error mapping.
- Secure token/session storage with `flutter_secure_storage`.
- Student authentication: login, registration, forgot password, OTP, logout.
- Face registration and verification using the front camera, local JPEG compression, and multipart upload.
- Student dashboard, courses, video learning, assessments, certificates, profile, and notification-ready services.
- Velzon-inspired Material UI: compact cards, metrics, badges, progress bars, and bottom navigation.

## Configure the API URL

Set the backend URL at build/run time:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/codex-thc-lms/api/
```

The endpoint constants live in:

```txt
lib/core/constants/api_endpoints.dart
```

Map those paths to the exact existing THC-LMS web APIs if the mounted backend project uses different URLs. The app is intentionally keeping API calls isolated so backend logic and workflows remain unchanged.

## Run

```sh
flutter pub get
flutter run
```

## Build Android

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://your-thc-lms-domain.com/api/
```

Release signing is still using Flutter's debug signing placeholder. Add your Android keystore before Play Store or enterprise distribution.

## Firebase notifications

The app has Firebase Messaging and local notification structure. Add the project-specific `google-services.json` to:

```txt
android/app/google-services.json
```

Then wire the backend device-token endpoint in `NotificationService`/student login flow if the existing LMS already supports push notification tokens.

## Notes

- This app is scoped to Students/Participants only.
- Admin, Manager, Instructor, reports management, and backend management screens are intentionally not included.
- Course progress, assessments, certificates, and face verification are delegated to the existing backend APIs.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
