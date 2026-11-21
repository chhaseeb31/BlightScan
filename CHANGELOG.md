# Changelog

## November 21, 2026 — Community refresh and Cloudinary image persistence

### Community experience
- Redesign the community feed with clearer post cards, a composer entry point, search, and Latest, Most liked, My posts, and With photos filters.
- Use the existing BlightScan color palette throughout the redesigned screen.
- Cover compact-screen layout, search, and feed filters with a widget regression test.

### Cloudinary and Firestore
- Add a shared unsigned multipart Cloudinary uploader with secure URL validation, timeout handling, and failure results.
- Upload leaf photos after successful classification and save the image URL, prediction, confidence, treatment steps, user ID, and server-generated timestamp to the top-level scan_history collection.
- Preserve legacy history reads and retain pending scans and durable local photos for retry after upload or sync failures.
- Display network images and saved treatment plans in History, with network image support in Home, Result, and Treatment screens.
- Add editable profile avatars that save Cloudinary photo URLs to the user's Firestore document without overwriting other profile fields.
- Surface history deletion failures and deploy owner-only scan_history rules.
- Document the storage flow, changed files, and verification limits in CLOUDINARY_INTEGRATION.md.

### Dependencies and verification
- Update Flutter metadata and the dependency lockfile, adopt the material_ui entry-point import, and add path_provider as a direct dependency for persistent scan photos. The http package was already available.
- Add regression coverage for Cloudinary multipart uploads and failures, Firestore history fields and user filters, and profile picture persistence.
- November 21 pre-push checks: all 98 tests passed; Flutter analysis completed with no errors or warnings and 59 informational lint/deprecation notices; staged whitespace checks passed.
- Android system Back changes and their regression coverage are detailed in the November 20 entry below.

### Remaining verification
- Confirm a live Cloudinary upload on a device; automated upload checks use mocked HTTP responses.
- Integrate the trained AI model before validating real leaf classification. Fallback diagnoses remain disabled.
- Community post photos still use their existing Firebase Storage flow; the Cloudinary change covers scan and profile images.

## November 20, 2026 — Android system Back

- Handle Android Back at shell tab roots through BackButtonListener because go_router 13 skips the root PopScope callback.
- Community, History, and Profile return to Home and save Home as the restoration destination. Back from Home retains normal Android exit behavior.
- Pushed scan/detail routes and dialogs are handled by the router before tab fallback. Background/resume preserves the current tab.
- Four navigation regression tests pass, covering tab roots, Home exit dispatch, saved restoration destination, nested details, scan, dialogs, and background/resume. Physical device verification is pending because no phone was connected.


## November 2026 — authentication, community, and scan reliability

### Authentication and startup
- Validate Firebase identity responses and provision the canonical user profile before publishing a signed-in session.
- Surface profile/authentication failures and allow sign-in retry after incomplete signup provisioning.
- Refresh expiring ID tokens, coalesce concurrent refreshes, and preserve the remember-me choice.
- Keep saved credentials on temporary restoration network failures.
- Render splash without the previous five-second initialization race, and navigate after session readiness.

### Community and Firebase
- Add deployable Firestore and Storage rules through firebase.json.
- Correct the /posts versus /community_posts permission mismatch while retaining legacy collection access.
- Preserve post fields when liking with a PATCH update mask; constrain changes to the current user's like membership.
- Add loading/error states, timeouts, duplicate-like guards, and rollback on failed updates.
- Upload JPEG/PNG photos using the REST session token under user-owned folders with a 10 MB limit and useful failure messages.
- Add the read-only rules inspection/backup helper and backend setup documentation.

### Scan, history, and notifications
- Preserve gallery selection across Android lifecycle transitions and restart the camera after retake.
- Handle preparation failures in the scan screen.
- Refresh history request tokens and clear cached history when accounts change.
- Remove fabricated demo reminders and prevent delayed reminders from crossing accounts.
- Block unreliable fallback diagnoses until a trained model is integrated.
- Dispose the post caption controller and guard repeated submissions/unmounted picker results.

### Configuration and verification
- Update Android Gradle/Kotlin configuration, Flutter metadata, Firebase dependencies, lockfile, and generated platform plugin registrations.
- Extend tests for identity/profile handling, token refresh, community request authentication and update masks, uploads, missing models, and notifications.
- November 14 checks: 88 suite tests plus one notification regression test passed; debug APK built and installed; saved login, Home screen, and community HTTP 200 verified on vivo 1938.
- Analysis passed with non-fatal Material deprecation notices. Debug frame drops and build-tool migration warnings remain.

### Remaining setup
- Complete billing/default Storage bucket setup, deploy storage.rules, and verify a live upload.
- Supply and integrate the trained model, labels, preprocessing, and output mapping.
- Complete release signing, performance profiling, and broader end-to-end testing. Comment counts are currently local updates rather than a server-maintained aggregate.

Generated build reports and temporary pre-upgrade backup files are local artifacts, not part of this source update.
