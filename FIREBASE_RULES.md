# Firestore Security Rules for BlightScan

Use these rules in Firebase Console → Firestore Database → Rules.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;

      match /scans/{scanId} {
        allow read, create, update, delete: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

These rules keep each user's profile and scan history private to that authenticated user.
