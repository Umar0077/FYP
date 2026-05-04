# NovaPrep Full Project Documentation

## 1. Project Overview

NovaPrep is a Flutter-based AI interview preparation platform with:

- User onboarding and authentication (email/password and Google Sign-In)
- Interview preparation and AI-generated interview questions
- Real-time interview session flow with timer, skip, speech input, and answer tracking
- Optional live camera-based emotion tracking during interviews
- Interview scoring and result analytics (accuracy, relevance, confidence)
- Streak tracking and user performance dashboards
- Support chat between users and admins
- Admin panel for user/interview/support management and analytics

The project uses Firebase (Auth, Firestore, Storage, Cloud Functions) plus Gemini APIs and an external emotion analysis backend.


## 2. Tech Stack

### 2.1 Frontend (Mobile/Desktop/Web)

- Flutter (Dart)
- GetX for routing, DI, and reactive state
- SharedPreferences (onboarding state)
- flutter_secure_storage (sensitive settings such as API keys)
- camera, speech_to_text, permission_handler, image_picker, url_launcher

### 2.2 Backend / Cloud

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions (Node.js 20)
- Two cloud codebases configured in `firebase.json`:
  - `functions` (default codebase)
  - `nlp` (secondary codebase)

### 2.3 AI / NLP / Emotion

- Gemini via `google_generative_ai` in Flutter
- Gemini via `@google/generative-ai` in Cloud Functions
- Embedding similarity + rubric scoring pipeline in Cloud Functions
- Emotion API backend (FastAPI-compatible endpoints) consumed by `EmotionApiClient`


## 3. High-Level Architecture

```text
UI (views/*)
  -> Controllers (GetX / state)
  -> Services (business logic / integrations)
  -> Repositories (support + clean-architecture Gemini path)
  -> Firebase + Cloud Functions + External APIs
```

There are two architectural patterns present:

1. App-first flow (primary path): `views` + `controllers` + `services`
2. Clean architecture chat module (secondary path): `domain` + `data` + `presentation`


## 4. Functional Modules

## 4.1 Authentication and Access Control

### User auth capabilities

- Register with email/password
- Login with email/password
- Login with Google Sign-In
- Password reset via email
- Email verification enforcement for password users
- Camera consent gating before entering dashboard

### Main files

- `lib/controllers/auth_controller.dart`
- `lib/views/auth/LoginScreen.dart`
- `lib/views/auth/RegisterScreen.dart`
- `lib/views/auth/ForgotPasswordMethodScreen.dart`
- `lib/views/auth/ForgotPasswordEmailScreen.dart`
- `lib/views/auth/CameraConsentScreen.dart`
- `lib/views/starting/SplashScreen.dart`

### Important behavior

- New user docs are written in `users/{uid}`
- `cameraConsentAccepted` is required for post-login dashboard access
- Password users are blocked from app access until `emailVerified == true`
- Google Sign-In error handling includes explicit guidance for Android `ApiException: 10`


## 4.2 Onboarding and App Entry

### Flow

1. Splash checks:
   - onboarding completion flag (`seenOnboarding`)
   - auth session validity
   - consent requirement
2. Routes to one of:
   - onboarding
   - login
   - camera consent
   - home

### Main files

- `lib/views/starting/SplashScreen.dart`
- `lib/views/starting/OnboardingScreen.dart`
- `lib/views/starting/WelcomeScreen.dart`


## 4.3 Interview Preparation and Session

### Preparation module

- Position selection
- Interview type selection
- Difficulty selection
- Question count selection (by difficulty rules)

Main file:

- `lib/views/main/InterviewPrepScreen.dart`

### Interview runtime module

- AI question generation with expected answers
- Session creation in Firestore
- Per-question timer
- Manual answer and speech-to-text input
- Skip and next behavior
- Attempt persistence to Firestore
- Cloud-based attempt evaluation trigger
- Interview completion and results persistence

Main files:

- `lib/views/main/InterviewScreen.dart`
- `lib/services/gemini_service.dart`
- `lib/services/interview_service.dart`
- `lib/services/nlp_cloud_service.dart`
- `lib/services/interview_result_service.dart`

### Restart behavior

When user taps Restart Interview from result screen, the app now restarts with the same:

- domain/position
- interview type
- question count
- difficulty

Flow implemented through parameter handoff from:

- `InterviewScreen -> InterviewResultScreen -> InterviewScreen`

Main files:

- `lib/views/main/InterviewScreen.dart`
- `lib/views/main/InterviewResultScreen.dart`


## 4.4 Emotion Tracking Module

### Capabilities

- Camera permission handling
- Session start/stop against emotion backend
- Periodic frame capture
- Multipart upload to emotion backend
- Session emotion report retrieval
- Confidence analysis input for final scoring UI
- Live camera preview in interview screen

### Main files

- `lib/config/emotion_tracking_config.dart`
- `lib/controllers/emotion_tracking_controller.dart`
- `lib/services/emotion_api_client.dart`
- `lib/services/frame_capture_service.dart`
- `lib/services/gemini_confidence_analyzer.dart`

### Config-driven behavior

- Base URL and preview toggles live in `EmotionTrackingConfig`
- Default capture interval is 900ms


## 4.5 Results, Dashboard, and Streaks

### Capabilities

- Aggregate interview metrics display
- Confidence analysis visualization
- Recent session listing
- Dashboard progress summary
- Practice streak tracking

### Main files

- `lib/views/main/InterviewResultScreen.dart`
- `lib/views/main/HomeScreen.dart`
- `lib/views/main/RecentScreen.dart`
- `lib/controllers/dashboard_controller.dart`
- `lib/controllers/recent_interviews_controller.dart`
- `lib/services/interview_stats_service_getx.dart`
- `lib/services/streak_service.dart`


## 4.6 Profile and Preferences

### Capabilities

- Profile data rendering from Firestore/Auth fallback
- Avatar upload to Firebase Storage
- Progress-aware upload UI
- Preferences and account information updates
- Password reset entry from preferences

### Main files

- `lib/views/main/ProfileScreen.dart`
- `lib/controllers/profile_controller.dart`
- `lib/views/main/PreferenceScreen.dart`
- `lib/views/main/EditInformationScreen.dart`

### Avatar upload implementation notes

- Upload path pattern: `users/{uid}/avatar_{timestamp}.jpg`
- Multi-bucket retry logic attempts:
  - default bucket
  - `{projectId}.appspot.com`
  - `{projectId}.firebasestorage.app`


## 4.7 Resources and Job Suggestions

### Resources

- Displays curated interview course cards
- Opens external URL via launcher

Files:

- `lib/views/main/ResourcesScreen.dart`
- `lib/views/course/CourseWebViewScreen.dart`
- `lib/models/interview_course.dart`

### Job suggestions

- Filterable suggestion cards
- Bookmark toggles
- Bottom-sheet details and apply/save actions

Files:

- `lib/views/main/JobSuggestionsScreen.dart`
- `lib/models/job_suggestion_model.dart`
- `lib/controllers/job_suggestions_controller.dart`

Note: current user-facing job list is sample/static in screen code.


## 4.8 Support Chat (User <-> Admin)

### Capabilities

- Auto-create one chat per user
- Real-time message stream
- Unread counters for both roles
- Read receipts (`isRead`, `readAt`)

### Main files

- `lib/views/main/SupportChatScreen.dart`
- `lib/services/support/support_chat_service.dart`
- `lib/repositories/support/support_chat_repository.dart`
- `lib/models/support/support_chat_model.dart`
- `lib/models/support/support_message_model.dart`
- `lib/views/admin/admin_support_screen.dart`
- `lib/views/admin/admin_support_chat_detail_screen.dart`


## 4.9 Admin Module

### Capabilities

- Admin login and route guard
- Dashboard metrics
- User management and leaderboard
- Interview management and details
- Result review and emotion tracking views
- Support chat handling
- Notifications and activity logs
- Settings persistence

### Main files

- `lib/services/admin/admin_auth_service.dart`
- `lib/services/admin/admin_data_service.dart`
- `lib/services/admin/admin_backend_service.dart`
- `lib/controllers/admin/admin_controller.dart`
- `lib/bindings/admin/admin_binding.dart`
- `lib/core/guards/admin_route_guard.dart`
- `lib/views/admin/*.dart`

### Access model

Admin verification checks either:

1. `users/{uid}.role == 'admin'`, or
2. matching email in `admin` collection


## 4.10 Theme, UI Infrastructure, and Navigation

### Capabilities

- Light and dark themes
- Reusable scaffold and glassmorphism card components
- Main tabs (Home/Resources/Recent/Profile)
- GetX route registry for user + admin paths

### Main files

- `lib/theme/app_theme.dart`
- `lib/views/widgets/AppScaffold.dart`
- `lib/views/widgets/GlassCard.dart`
- `lib/views/main/MainTabs.dart`
- `lib/main.dart`


## 4.11 Clean-Architecture Gemini Chat (Secondary Module)

This project contains an additional generic Gemini chat architecture alongside interview flow.

### Layering

- Domain: entities/use cases/repository contract
- Data: models/datasource/repository implementation
- Presentation: chat/settings screens and controllers
- DI: service registration in `core/di/injection.dart`

### Main files

- `lib/domain/*`
- `lib/data/*`
- `lib/presentation/*`
- `lib/core/di/injection.dart`


## 5. End-to-End Workflows

## 5.1 New User (Email/Password)

1. Open app -> Splash
2. Complete onboarding (first time only)
3. Register
4. Firebase user created + Firestore `users/{uid}` created
5. Verification email sent
6. User must verify email
7. Login
8. Camera consent screen (if not accepted)
9. Home dashboard


## 5.2 New User (Google)

1. Login screen -> Continue with Google
2. Firebase sign-in with Google credential
3. If first login, app creates `users/{uid}`
4. Camera consent check
5. Home dashboard


## 5.3 Interview Session

1. User selects prep inputs in Interview Prep
2. Gemini generates question + answer pairs
3. App creates `interviews/{interviewId}`
4. During each question:
   - timer runs
   - user answers or skips
   - attempt saved under `interviews/{id}/attempts`
   - cloud evaluation requested
5. On completion:
   - interview aggregation performed
   - confidence analysis generated
   - result saved in `interview_result/{id}`
6. Result screen shows metrics and actions


## 5.4 Restart Interview

1. User taps Restart Interview in result screen
2. App rehydrates previous setup from passed params and/or loaded interview data
3. Starts new interview with same configuration


## 5.5 Support Chat

1. User opens support from profile
2. Chat record auto-created if needed
3. User messages are written to `support_chats/{chatId}/messages`
4. Admin sees chat in admin support screens and replies
5. Both sides receive real-time updates


## 6. Firebase Data Model (Practical Schema)

## 6.1 Collections

### `users/{uid}`

Common fields seen in app:

- `name`, `email`, `phone`, `dob`, `dob_iso`
- `photoUrl` / `photoURL`
- `cameraConsentAccepted`, `cameraConsentAcceptedAt`
- `signInMethod`
- `currentStreak`, `longestStreak`, `lastPracticeDate`, `practiceDates`
- `role` (admin check)
- timestamps (`createdAt`, `updatedAt`, `lastUpdated`)

### `interviews/{interviewId}`

Common fields:

- `userId`, `difficulty`, `questionCount`, `position`, `interviewType`
- `status`, `startedAt`, `endedAt`
- counts: `answeredCount`, `skippedCount`, `wrongCount`, `correctCount`, `totalCount`
- aggregates: `accuracyOverall`, `relevanceOverall`, `avgAccuracy`, `avgRelevance`
- metadata: `resultVersion`, `resultSource`, `computedAt`

### `interviews/{interviewId}/attempts/{attemptId}`

- input: `questionText`, `correctAnswer`, `userAnswer`, `status`
- context: `questionId`, `position`, `interviewType`, `createdAt`
- evaluation fields:
  - `relevanceGemini`, `accuracyGemini`
  - `embeddingSimilarity`, `embeddingScore`
  - `relevanceFinal`, `accuracyFinal`
  - `feedback`, `missingPoints`, `wrongClaims`
  - `evaluationStatus`, `evaluatedAt`

### `interview_result/{interviewId}`

- identifiers: `userId`, `interviewId`, `sessionId`
- metrics: `accuracyOverall`, `relevanceOverall`, `avgAccuracy`, `avgRelevance`
- confidence: `confidenceLevel`, `confidenceLabel`, `confidenceAnalysis`
- emotion: `emotionReport`
- counts: `answeredCount`, `skippedCount`, `wrongCount`, `correctCount`, `totalCount`
- lifecycle fields: `startedAt`, `endedAt`, `computedAt`, `status`

### `support_chats/{chatId}` and `support_chats/{chatId}/messages/{messageId}`

Chat document fields:

- `chatId`, `userId`, `userName`, `userEmail`
- `lastMessage`, `lastMessageTime`, `lastSenderRole`
- `adminUnreadCount`, `userUnreadCount`, `isOpen`
- `createdAt`, `updatedAt`

Message document fields:

- `messageId`, `senderId`, `senderRole`, `text`
- `createdAt`, `isRead`, `readAt`

### Admin-oriented collections

- `admin`
- `resources`
- `job_suggestions`
- `support_tickets`
- `admin_notifications`
- `admin_activity_logs`
- `admin_settings`

### Embedding cache collection

- `questions/{questionId}` with cached `correctAnswerEmbedding`


## 7. Security Rules and Storage Rules

- Firestore rules in `firestore.rules`
- Storage rules in `storage.rules`

Key points:

- Signed-in users can read/update their own user docs
- Interview docs gated by ownership/admin role
- Support chat docs gated by owner/admin
- Storage upload is constrained to `users/{uid}/**`, image content types, and size limits


## 8. Cloud Functions and Evaluation Pipeline

## 8.1 Codebases

- `functions/` (default)
- `nlp/` (second codebase with similar evaluation modules)

## 8.2 Core function behavior

### Firestore trigger evaluation

- Trigger: `interviews/{interviewId}/attempts/{attemptId}` on create
- Steps:
  1. Validate attempt
  2. Handle skipped/empty answers as zero
  3. Gemini rubric scoring
  4. Embedding generation and similarity
  5. Weighted final scores
  6. Persist attempt results

Main file:

- `functions/src/evaluateAttempt.js`

### Callable aggregate recomputation

- Callable endpoint recomputes interview aggregate from attempts

Main file:

- `functions/src/aggregateInterview.js`

### Supporting modules

- `functions/src/geminiRubricScore.js`
- `functions/src/geminiEmbeddings.js`
- `functions/src/firestoreCache.js`
- `functions/src/cosineSimilarity.js`


## 9. Routing Map

Defined in `lib/main.dart` via `GetPage`.

### User routes

- `/`, `/onboarding`, `/welcome`
- `/login`, `/register`, `/camera-consent`
- `/forgot`, `/forgot/email`
- `/home`, `/resources_tab`, `/recent_tab`, `/profile_tab`
- `/interview_prep`, `/interview`, `/interview_result`
- `/profile/preferences`, `/profile/edit-info`, `/profile/support`
- `/practical_questions`, `/job_suggestions`

### Admin routes

- `/admin/login`
- `/admin/dashboard`
- `/admin/users`, `/admin/users/leaderboard`, `/admin/users/detail`
- `/admin/interviews`, `/admin/interviews/detail`, `/admin/interviews/results`
- `/admin/emotion_tracking`
- `/admin/support`, `/admin/support/chat`
- `/admin/analytics`, `/admin/notifications`, `/admin/logs`, `/admin/settings`


## 10. Dependency Injection and State Management

### Primary app bindings

- `AppBinding`: permanent auth + stats service
- `MainBinding`: dashboard + recent interview controllers
- `InterviewBinding`: interview controller

Files:

- `lib/bindings/app_bindings.dart`
- `lib/bindings/admin/admin_binding.dart`

### Secondary clean-architecture DI

- `lib/core/di/injection.dart`


## 11. Environment and Configuration

## 11.1 Firebase setup

- FlutterFire-generated options in `lib/firebase_options.dart`
- Android app config in `android/app/google-services.json`
- Firestore + Storage rules wired in `firebase.json`

## 11.2 Android build/signing

- `android/app/build.gradle.kts` includes:
  - `com.google.gms.google-services`
  - project debug signing config (`projectDebug`)

## 11.3 Emotion backend URL

- Controlled in `lib/config/emotion_tracking_config.dart`
- Also configurable in settings controller path (`presentation/settings` module)


## 12. Run and Deployment Guide

## 12.1 Flutter app

```bash
flutter pub get
flutter run
```

## 12.2 Static analysis and tests

```bash
flutter analyze
flutter test
```

## 12.3 Deploy Firebase rules/functions

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only functions
```

For codebase-specific deployment, use Firebase codebase selectors as needed.


## 13. Testing Overview

Tests currently present in `test/`:

- `gemini_chat_service_test.dart`
- `generate_json_usecase_test.dart`
- `send_message_usecase_test.dart`
- `nlp_evaluation_test.dart` (script-like integration style)
- `widget_test.dart` (default scaffold test)

Testing focus today is strongest around Gemini use cases and unit behavior in clean-architecture module.


## 14. Known Design Notes and Observations

1. There are overlapping/parallel modules (main interview flow + clean-architecture chat module).
2. `functions` and `nlp` codebases both contain evaluation logic; maintain consistency carefully.
3. User job suggestions screen currently uses static sample data in UI code.
4. Some admin backend integration methods are placeholder-style (`admin_backend_service.dart`).
5. `widget_test.dart` is still default counter test and does not reflect app-specific UI.


## 15. Full Source Inventory (Core)

### Flutter source

- `lib/main.dart`
- `lib/firebase_options.dart`
- `lib/gemini_test.dart`

#### Bindings

- `lib/bindings/app_bindings.dart`
- `lib/bindings/admin/admin_binding.dart`

#### Config

- `lib/config/emotion_tracking_config.dart`

#### Controllers

- `lib/controllers/auth_controller.dart`
- `lib/controllers/dashboard_controller.dart`
- `lib/controllers/emotion_session_controller.dart`
- `lib/controllers/emotion_tracking_controller.dart`
- `lib/controllers/interview_controller.dart`
- `lib/controllers/job_suggestions_controller.dart`
- `lib/controllers/profile_controller.dart`
- `lib/controllers/recent_interviews_controller.dart`
- `lib/controllers/admin/admin_controller.dart`

#### Core

- `lib/core/constants/app_constants.dart`
- `lib/core/di/injection.dart`
- `lib/core/guards/admin_route_guard.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/utils/secure_storage.dart`

#### Data

- `lib/data/datasources/gemini_remote_datasource.dart`
- `lib/data/models/gemini_message.dart`
- `lib/data/models/gemini_settings.dart`
- `lib/data/repositories/gemini_repository_impl.dart`

#### Domain

- `lib/domain/entities/chat_settings.dart`
- `lib/domain/entities/message.dart`
- `lib/domain/repositories/gemini_repository.dart`
- `lib/domain/usecases/generate_json_usecase.dart`
- `lib/domain/usecases/send_message_usecase.dart`
- `lib/domain/usecases/send_message_with_system_usecase.dart`

#### Models

- `lib/models/interview_course.dart`
- `lib/models/job_suggestion_model.dart`
- `lib/models/admin/admin_mock_models.dart`
- `lib/models/support/support_chat_model.dart`
- `lib/models/support/support_message_model.dart`

#### Presentation

- `lib/presentation/controllers/chat_controller.dart`
- `lib/presentation/controllers/settings_controller.dart`
- `lib/presentation/screens/chat_screen.dart`
- `lib/presentation/screens/settings_screen.dart`
- `lib/presentation/widgets/chat_input.dart`
- `lib/presentation/widgets/message_bubble.dart`

#### Repositories

- `lib/repositories/support/support_chat_repository.dart`

#### Services

- `lib/services/embeddings_service.dart`
- `lib/services/emotion_api_client.dart`
- `lib/services/frame_capture_service.dart`
- `lib/services/gemini_chat_service.dart`
- `lib/services/gemini_confidence_analyzer.dart`
- `lib/services/gemini_service.dart`
- `lib/services/interview_result_service.dart`
- `lib/services/interview_service.dart`
- `lib/services/interview_stats_service.dart`
- `lib/services/interview_stats_service_getx.dart`
- `lib/services/nlp_cloud_service.dart`
- `lib/services/nlp_evaluation_service.dart`
- `lib/services/streak_service.dart`
- `lib/services/admin/admin_auth_service.dart`
- `lib/services/admin/admin_backend_service.dart`
- `lib/services/admin/admin_data_service.dart`
- `lib/services/support/support_chat_service.dart`

#### Theme

- `lib/theme/app_theme.dart`

#### Views - Admin

- `lib/views/admin/admin_activity_logs_screen.dart`
- `lib/views/admin/admin_analytics_screen.dart`
- `lib/views/admin/admin_dashboard_screen.dart`
- `lib/views/admin/admin_emotion_tracking_screen.dart`
- `lib/views/admin/admin_interview_detail_screen.dart`
- `lib/views/admin/admin_interview_management_screen.dart`
- `lib/views/admin/admin_job_suggestions_management_screen.dart`
- `lib/views/admin/admin_login_screen.dart`
- `lib/views/admin/admin_notifications_screen.dart`
- `lib/views/admin/admin_resources_management_screen.dart`
- `lib/views/admin/admin_results_review_screen.dart`
- `lib/views/admin/admin_settings_screen.dart`
- `lib/views/admin/admin_support_chat_detail_screen.dart`
- `lib/views/admin/admin_support_screen.dart`
- `lib/views/admin/admin_user_detail_screen.dart`
- `lib/views/admin/admin_user_leaderboard_screen.dart`
- `lib/views/admin/admin_user_management_screen.dart`

#### Views - Auth

- `lib/views/auth/CameraConsentScreen.dart`
- `lib/views/auth/ForgotPasswordEmailScreen.dart`
- `lib/views/auth/ForgotPasswordMethodScreen.dart`
- `lib/views/auth/LoginScreen.dart`
- `lib/views/auth/RegisterScreen.dart`

#### Views - Course

- `lib/views/course/CourseWebViewScreen.dart`

#### Views - Main

- `lib/views/main/EditInformationScreen.dart`
- `lib/views/main/HomeScreen.dart`
- `lib/views/main/InterviewPrepScreen.dart`
- `lib/views/main/InterviewResultScreen.dart`
- `lib/views/main/InterviewScreen.dart`
- `lib/views/main/JobSuggestionsScreen.dart`
- `lib/views/main/MainTabs.dart`
- `lib/views/main/PracticalQuestionsScreen.dart`
- `lib/views/main/PreferenceScreen.dart`
- `lib/views/main/ProfileScreen.dart`
- `lib/views/main/RecentScreen.dart`
- `lib/views/main/ResourcesScreen.dart`
- `lib/views/main/SupportChatScreen.dart`

#### Views - Starting

- `lib/views/starting/OnboardingScreen.dart`
- `lib/views/starting/SplashScreen.dart`
- `lib/views/starting/WelcomeScreen.dart`

#### UI and shared widgets

- `lib/views/ui/ui_colors.dart`
- `lib/views/widgets/AppScaffold.dart`
- `lib/views/widgets/GlassCard.dart`


### Cloud Functions source

- `functions/src/index.js`
- `functions/src/evaluateAttempt.js`
- `functions/src/aggregateInterview.js`
- `functions/src/geminiRubricScore.js`
- `functions/src/geminiEmbeddings.js`
- `functions/src/firestoreCache.js`
- `functions/src/cosineSimilarity.js`

### NLP codebase source

- `nlp/index.js`
- `nlp/src/evaluateAttempt.js`
- `nlp/src/aggregateInterview.js`
- `nlp/src/geminiRubricScore.js`
- `nlp/src/geminiEmbeddings.js`
- `nlp/src/firestoreCache.js`
- `nlp/src/cosineSimilarity.js`

### Tests

- `test/gemini_chat_service_test.dart`
- `test/gemini_chat_service_test.mocks.dart`
- `test/generate_json_usecase_test.dart`
- `test/generate_json_usecase_test.mocks.dart`
- `test/nlp_evaluation_test.dart`
- `test/send_message_usecase_test.dart`
- `test/send_message_usecase_test.mocks.dart`
- `test/widget_test.dart`


## 16. Project Maintenance Checklist

When updating this project, verify all of the following:

1. Firebase config consistency (`firebase_options.dart`, Android/iOS config files, rules)
2. Auth and consent gates (Splash/Login/Register/AuthController)
3. Interview runtime and result persistence (InterviewScreen + services)
4. Cloud function compatibility for attempt scoring and aggregation
5. Emotion backend URL and availability
6. Support chat permissions and unread counters
7. Admin role checks and guarded route access
8. Tests and analyzer output


---

This document reflects the current codebase state in this workspace and is intended to serve as a complete functional and technical reference for NovaPrep.
