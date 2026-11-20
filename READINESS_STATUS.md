# BlightScan verification — 2026-11-14

## Completed
- Deployed Firestore collection permission fix. On the connected vivo 1938, community loading returned HTTP 200 (previously 403). Existing legacy posts rules were preserved.
- Render startup immediately and wait for session readiness before leaving splash.
- Refresh REST login tokens before community/history operations; preserve the remember-me choice.
- Protect post fields with an explicit update mask during likes, add request timeouts, and guard repeated likes.
- Implement authenticated Storage multipart uploads in user-owned folders, validate JPEG/PNG and a 10 MB limit, and surface actionable upload errors. Regression-tested the request using a mock server.
- Fix native gallery selection being invalidated when Android backgrounds the scan screen, and camera restart after retake.
- Clear cached history on account change; remove fabricated demo notifications.
- Prevent the demo byte heuristic from producing a diagnosis through the analysis repository while the trained model is absent.

## Verification
- Flutter test suite: 88 tests passed, followed by the new notification regression test passing (89 total).
- Flutter analyze --no-fatal-infos: successful, with 48 existing Material import deprecation notices. This is not a clean zero-notice analysis.
- Latest debug APK built successfully: build/app/outputs/flutter-apk/app-debug.apk.
- Physical device: installed debug APK, confirmed saved session restoration, Home screen, and community HTTP 200. Initial Android launch wait timed out, but subsequent inspection confirmed the activity running and the Home screen displayed.
- git diff --check passed.

## Still required before calling the app production-ready
1. Owner must complete Firebase billing/Storage setup. Storage deployment failed because no Storage bucket has been set up. storage.rules and firebase.json are ready; see FIREBASE_RULES.md. Live photo upload/download remains unverified.
2. Supply the trained model, labels, input normalization and output class mapping. No .tflite model exists in this repository. A real interpreter and accuracy validation still need implementation; changing usesFallbackModel alone is not sufficient.
3. Profile/release-mode performance measurement on the device. Debug startup still reports skipped frames; no claim of eliminating all frame drops is made.
4. Build-tool and plugin migration warnings remain (Gradle/AGP/Kotlin and built-in Kotlin). Current debug build passes. Release signing and store deployment have not been configured or verified.
5. Full end-to-end coverage of posting, concurrent likes/comments, camera/gallery permissions and offline flows remains beyond the smoke checks performed here. Existing comment counts are updated locally and are not a server-maintained aggregate.

No user posts or comments were published during verification.
