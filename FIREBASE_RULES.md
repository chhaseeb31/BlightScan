# Firebase access configuration

The deployable source of truth is firestore.rules and storage.rules, referenced by firebase.json.

Firestore rules were deployed to blightscan-2026 on 2026-11-14. The previous release is backed up in build/rules-backup/deployed.json.

The community permission error was a collection mismatch: deployed rules covered /posts, but the app uses /community_posts. Legacy /posts permissions are retained. New community rules allow signed-in reads, author-owned creation/deletion, and likes that can only add/remove the current user. Profile and scan history remain owner-only.

Community uploads use the existing REST login token, with images stored under community_posts/{uid}/{file}. Uploads accept JPEG/PNG smaller than 10 MB. No public-write rules are used.

Storage deployment is pending: Firebase reports that Storage has not been set up. After the project owner completes billing and creates the default bucket, run:

    firebase deploy --only storage --project blightscan-2026

Configured bucket: blightscan-2026.firebasestorage.app. If setup creates a different bucket, update storageBucket in lib/firebase_options.dart before rebuilding.

References:
- https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/patch
- https://firebase.google.com/docs/firestore/security/rules-fields
- https://github.com/firebase/firebase-js-sdk/blob/main/packages/storage/src/implementation/requests.ts
