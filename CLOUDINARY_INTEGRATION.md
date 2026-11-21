# Cloudinary image integration

Leaf scans and profile pictures use cloud `nppmhtyz` with unsigned upload preset `jloxzriq`. The shared uploader sends multipart `file` and `upload_preset`, validates `secure_url`, and returns null on upload failure. No API secret is stored in the app.

Successful classifications are saved to `/scan_history/{scanId}` with `userId`, `imageUrl`, `prediction`, `confidence` (0–1), `treatmentPlan` (list of steps), and `timestamp`. This app authenticates through Firebase Identity Toolkit REST, so the Firestore commit uses `REQUEST_TIME`, the server transform equivalent of `FieldValue.serverTimestamp()`.

History queries filter by the signed-in user and retain support for legacy `/users/{uid}/scans`. Images use `Image.network` with broken-image fallback. Failed uploads retain a local photo and pending record; opening or refreshing History retries synchronization. Deleting a history record does not delete the Cloudinary asset: authenticated asset deletion requires a trusted backend, not an API secret in Flutter.

Tap the edit icon on either profile avatar to choose a photo. The uploaded URL is saved to `/users/{uid}.photoUrl` with an update mask that preserves other profile fields.

## Changed files

- `lib/core/services/cloudinary_service.dart`: shared multipart uploader.
- `lib/core/services/scan_history_service.dart`: upload, durable local photo, pending sync.
- `lib/core/data_sources/scan_history_remote_data_source.dart`: query and commit new Firestore schema.
- `lib/core/repositories/scan_history_repository.dart`: preserve pending records and surface deletion failure.
- `lib/features/history/domain/models/scan_history_record.dart`: URL, saved plan and sync status.
- `lib/features/scan/presentation/providers/scan_controller.dart`: pass treatment steps after classification.
- `lib/features/scan/presentation/screens/scan_screen.dart`: show sync failure message.
- `lib/features/history/presentation/screens/history_screen.dart`: network images, treatment and pending state.
- `lib/features/home/presentation/screens/home_screen.dart`: network history thumbnails.
- `lib/features/result/presentation/screens/result_screen.dart`: network leaf images.
- `lib/features/result/presentation/screens/treatment_plan_screen.dart`: network leaf images.
- `lib/core/services/firebase_user_profile_service.dart`: read/write profile photo URL.
- `lib/core/services/auth_session_service.dart`: profile photo session state.
- `lib/features/profile/presentation/widgets/profile_photo_avatar.dart`: photo picker and upload feedback.
- `lib/features/profile/presentation/screens/profile_screen.dart`: editable avatars.
- `firestore.rules`: owner-only scan history access.
- `pubspec.yaml`, `pubspec.lock`: direct `path_provider` dependency for durable local photos; `http` already existed.
- `test/cloudinary_history_test.dart`, `test/firebase_user_profile_service_test.dart`: upload, schema, query and profile persistence checks.

## Verification limits

Automated upload tests use mocked HTTP responses; the unsigned preset still needs a real device upload to confirm its Cloudinary dashboard settings. Real leaf classification remains blocked by the pre-existing missing trained model (`usesFallbackModel = true`). No fabricated diagnosis is enabled. Community post uploads are outside this change and still use their existing Firebase Storage flow.
