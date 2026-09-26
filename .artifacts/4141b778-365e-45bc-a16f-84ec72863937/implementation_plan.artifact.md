# BlightScan Professional Audit & Improvement Plan

This plan outlines the steps to transform BlightScan into a professional, production-ready application by implementing the Community and Notification features, improving the Home and Profile screens, and ensuring architectural consistency.

## User Review Required

> [!IMPORTANT]
> The current project uses **Firestore and Auth REST APIs** via the `http` package instead of the official Firebase SDKs. I will continue this pattern for the new Community and Notification features to maintain consistency and avoid increasing the app's binary size unnecessarily, unless you prefer switching to the full Firebase SDK.

> [!NOTE]
> I will be adding the `intl` package to `pubspec.yaml` for professional date formatting in the Community feed and History screens.

## Proposed Changes

### 1. Core & Architecture

*   **[NEW]** `lib/core/services/notification_service.dart`: Manage in-app notifications and treatment reminders.
*   **[NEW]** `lib/features/community/data/services/community_service.dart`: Firestore REST service for posts, likes, and comments.
*   **[MODIFY]** `lib/core/utils/app_routes.dart`: Remove `diagnose` route, add `community` and `notifications` routes.
*   **[DELETE]** `lib/features/scan/presentation/screens/diagnose_screen.dart`: Remove redundant standalone diagnosis page.

### 2. Home Screen Improvements

*   **[MODIFY]** `lib/features/home/presentation/screens/home_screen.dart`:
    *   Header: Add polished profile avatar (with fallback) and notification icon with unread badge.
    *   Remove "What BlightScan detects" info card.
    *   Refactor "Quick Guidance" section to be a horizontally scrollable row of premium cards with professional icons.
*   **[MODIFY]** `lib/features/home/presentation/screens/main_screen.dart`: Replace "Diagnose" tab with "Community".

### 3. Community Feature

*   **[NEW]** `lib/features/community/presentation/screens/community_screen.dart`: Main feed showing user posts with likes and comments.
*   **[NEW]** `lib/features/community/presentation/screens/create_post_screen.dart`: UI for creating new posts with image upload.
*   **[NEW]** `lib/features/community/data/models/community_post.dart`: Data model for posts.

### 4. Notification System

*   **[NEW]** `lib/features/notifications/presentation/screens/notification_screen.dart`: List of in-app notifications.
*   **[NEW]** `lib/features/notifications/data/models/app_notification.dart`: Data model for notifications.

### 5. Profile & History Polish

*   **[MODIFY]** `lib/features/profile/presentation/screens/profile_screen.dart`: Audit and fix all links/actions, improve visual layout.
*   **[MODIFY]** `lib/features/history/presentation/screens/history_screen.dart`: Improve card hierarchy and metadata display.

## Verification Plan

### Automated Verification
*   `flutter analyze` to ensure no linting or type errors.
*   `flutter build apk --debug` to verify the build still succeeds.

### Manual Verification
*   Verify the **Community** tab replaces **Diagnose** in the bottom bar.
*   Verify the **Community feed** loads and displays posts from Firestore.
*   Verify **creating a post** with an image works and appears in the feed.
*   Verify the **Notification icon** appears on Home and correctly displays a badge for unread notifications.
*   Verify the **Quick Guidance** cards are scrollable and use icons instead of assets.
*   Verify all buttons on the **Profile screen** perform their expected actions.
*   Verify **Scan History** correctly navigates to result details.
