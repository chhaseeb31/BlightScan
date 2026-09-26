# BlightScan Fix Report

This report summarizes the code cleanup and completion work applied to the Flutter project.

## Scope Alignment

The app is now aligned with the actual FYP scope:

- App name: BlightScan
- Crop: Tomato
- Disease: Tomato Late Blight
- Classes: Healthy Tomato Leaf and Tomato Late Blight
- Backend: Firebase Auth + Cloud Firestore
- Mobile app: Flutter

## Major Changes

### Branding

- Updated user-facing branding to BlightScan.
- Updated splash, onboarding, home, auth, result, help, profile, and app metadata text.
- Re-generated Android, iOS, and Web launcher icons from `assets/blightscan_logo.png`.

### Removed Irrelevant Features

Removed old/non-scope modules:

- articles
- bookmarks
- community
- notifications
- reminders
- insights
- generic disease exploration
- multi-crop disease content

### Firebase Integration

Added:

- Firebase Auth REST session flow.
- User profile upsert to Firestore at `users/{uid}`.
- Scan history save/read/delete at `users/{uid}/scans/{scanId}`.
- Local cache fallback using SharedPreferences.
- Firestore rules documentation in `FIREBASE_RULES.md`.

### AI / Scan Flow

Added/updated:

- Tomato Late Blight-focused analysis service.
- Healthy vs Late Blight result mapping.
- Image validation and quality warnings.
- Camera/gallery image input.
- Result saved to Firestore + local cache.

Important: final trained TFLite model is not included in the submitted assets. A deterministic fallback classifier is present only to keep app flow testable until `assets/models/blightscan_model.tflite` and `assets/models/labels.txt` are added.

### UI/UX

Updated:

- Focused home dashboard.
- Tomato Late Blight guide screen.
- Real project assets/icons on home and guidance cards.
- Scan history screen with search, empty state, delete, and result reopen.
- Result/treatment screens with actual Tomato Late Blight information.
- Help/about/settings/profile content aligned to FYP scope.

### Security / Permissions

Added:

- Android camera/gallery/internet permissions.
- iOS camera/photo library usage descriptions.
- Private Firestore rules for per-user data.
- Auth route guards.

## Remaining Required Step Before Final Defense

Add the trained model files:

```text
assets/models/blightscan_model.tflite
assets/models/labels.txt
```

Then replace the fallback classifier inside:

```text
lib/core/services/ml_disease_detection_service.dart
```

with actual TensorFlow Lite interpreter inference.

## Local Verification Commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
flutter build apk --release
```
