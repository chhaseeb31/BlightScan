# BlightScan

***AI-Based Tomato Late Blight Detection Mobile Application***

BlightScan is a Flutter + Firebase Final Year Design Project focused on one crop and one disease: **Tomato + Late Blight**. The app lets a user capture or upload a tomato leaf image, runs disease analysis, shows a result with confidence, provides treatment/prevention guidance, and saves scan history for the signed-in user.

> Current AI status: no trained `.tflite` model is bundled. Disease analysis is intentionally blocked with an explicit message until real inference, labels, and preprocessing are integrated. The old fallback must not be treated as a reliable diagnosis.

## Latest update — November 2026

Authentication/session restoration, community permissions, photo upload handling, startup navigation, and camera/gallery lifecycle fixes are included in this update. The community permission fix was verified on a physical vivo phone (HTTP 200).

See [CHANGELOG.md](CHANGELOG.md) for the changes, [READINESS_STATUS.md](READINESS_STATUS.md) for recorded checks and remaining work, and [FIREBASE_RULES.md](FIREBASE_RULES.md) for backend setup. Validation listed there was performed on November 14, 2026; this documentation update does not imply a new device test.

## Core Scope

- Crop: Tomato
- Disease: Tomato Late Blight
- Classes: Healthy Tomato Leaf, Tomato Late Blight
- Platform: Android first, iOS optional
- Backend: Firebase Auth + Cloud Firestore
- AI deployment target: TensorFlow Lite on device

## Completed Cleanups

- Updated the user-facing app identity from the previous generic plant scope to **BlightScan**.
- Simplified the original multi-crop scope. The current app includes community posts and notifications alongside the tomato scan flow.
- Rebuilt the main app flow around the actual FYP scope: splash, onboarding, authentication, home dashboard, tomato guide, scan, result, history, profile, settings, help, and about.
- Replaced hardcoded old sample disease results with Tomato Late Blight / Healthy Tomato Leaf result handling.
- Added Firestore scan-history service with local cache fallback.
- Added Firebase user profile upsert after login/signup.
- Added image quality checks before analysis.
- Generated Android/iOS/Web launcher icons from `assets/blightscan_logo.png`.
- Added Android/iOS camera and gallery permissions.
- Added clearer empty states, delete history flow, and safer route guards.

## Features

### Authentication

- Login
- Signup
- Forgot/reset password route
- Persistent local auth session
- Firestore user profile document creation/update

### Scan Flow

- Camera capture
- Gallery image pick
- Image quality validation
- Disease analysis service layer
- Result screen with confidence, status, severity, symptoms, treatment, and prevention
- Scan saved to Firestore and local cache

### History

- Per-user scan history under `users/{uid}/scans/{scanId}`
- Local cache fallback when Firestore is unavailable
- Search history by result/status/crop
- Delete scan from local cache and Firestore
- Tap a history item to reopen the result

### UI/UX

- Focused BlightScan branding
- Tomato/Late Blight-specific guidance
- Real assets used from the project asset folder
- Responsive cards/list layouts
- Farmer-friendly labels and warnings

## Architecture

```text
lib/
  main.dart
  firebase_options.dart
  core/
    config/
    constants/
    repositories/
    services/
    theme/
    utils/
    widgets/
  features/
    auth/
    help/
    history/
    home/
    onboarding/
    profile/
    result/
    scan/
    settings/
    splash/
```

Recommended responsibility split:

- **Screens**: UI only
- **Services**: Firebase, scan history, image quality, auth session, ML service
- **Repository**: disease-analysis business flow
- **Models**: typed data structures
- **Core widgets/constants**: reusable design system pieces

## Firebase Setup

The existing Firebase project id is configured as:

```dart
blightscan-2026
```

For Android, the current Firebase package id in `google-services.json` is:

```text
com.example.blightscan
```

Keep this package id unless you also create a new Android app inside Firebase and download a matching `google-services.json`.

### Required Firebase Services

Enable these in Firebase Console:

1. Authentication → Email/Password
2. Cloud Firestore

### Suggested Firestore Rules

See `FIREBASE_RULES.md`.

## AI Model Integration Point

Expected final assets:

```text
assets/models/blightscan_model.tflite
assets/models/labels.txt
```

Expected labels:

```text
Healthy
Tomato Late Blight
```

Integration file:

```text
lib/core/services/ml_disease_detection_service.dart
```

Replace `_predictWithFallbackClassifier(...)` with actual TFLite interpreter inference after adding the trained model and image preprocessing.

## Run Locally

```bash
flutter clean
flutter pub get
flutter run
```

## Build Release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Before Final Submission

- Add the trained TFLite model and labels.
- Run `flutter analyze` and fix any environment-specific warnings.
- Test login/signup with a fresh Firebase user.
- Test Firestore scan saving and history retrieval.
- Test camera/gallery permissions on a real Android phone.
- Build release APK.
- Add screenshots and demo video to the final report.
- For Play Store release, change the package id from `com.example.blightscan` only after updating Firebase Android app configuration.

## FYP Team

- Haseeb Shafaqat
- Tayyab Maqbool
- Raza Ahmad

Supervisor: Mr. Sohail Zia
