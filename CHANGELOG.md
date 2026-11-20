# Changelog

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
