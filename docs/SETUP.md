# Setup

This document describes the current local setup for the LogCal iOS app and Firebase backend.

## Scope

- iOS app in `logcal/`
- web app in `web/`
- Firebase Functions in `functions/`
- Firebase project config in the repo root

Android exists in the repository, but it is intentionally out of scope for this setup guide.

## Prerequisites

- macOS with Xcode installed
- Node.js 20 for Firebase Functions
- Firebase CLI
- A Firebase project
- An iOS device or simulator

## Repository Areas

- `logcal/`: SwiftUI app
- `web/`: Next.js marketing site and future web app shell
- `functions/`: Firebase Functions TypeScript project
- `firebase.json`, `firestore.rules`, `storage.rules`: Firebase config
- `logcal.xcodeproj/`: iOS project

## iOS Setup

### 1. Open the project

Open `logcal.xcodeproj` in Xcode.

### 2. Confirm package dependencies

The app code expects Firebase packages and related auth packages to be present in Xcode.
Based on the code, the app uses at least:

- FirebaseCore
- FirebaseAuth
- FirebaseFunctions
- FirebaseFirestore
- FirebaseAnalytics
- GoogleSignIn
- Lottie

If Xcode reports missing packages, add the required packages before trying to build.

### 3. Add Firebase plist

Add `GoogleService-Info.plist` for the Firebase project to the Xcode target.

The app calls `FirebaseApp.configure()` during startup, so this file must be present for Firebase-backed builds.

### 4. Configure auth providers

The app currently supports:

- Google Sign-In
- Sign in with Apple
- Anonymous Firebase auth as a backend fallback path

Important: the current app startup flow is built around signed-in users. Some older docs describe auth as optional, but that no longer reflects the latest app logic.

### 5. Build and run

Build the `logcal` target from Xcode.

## Firebase Functions Setup

### 1. Install dependencies

```bash
cd functions
npm install
```

### 2. Set the OpenAI secret

The Functions backend expects the OpenAI API key in the `OPENAI_API_KEY` environment secret.

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

### 3. Build functions

```bash
cd functions
npm run build
```

### 4. Deploy functions

```bash
firebase deploy --only functions
```

## Web Setup

### 1. Install dependencies

```bash
cd web
npm install
```

### 2. Run the site locally

```bash
cd web
npm run dev
```

### 3. Build the static export

```bash
cd web
npm run build
```

This generates the Firebase-ready static output in `web/out`.

## Firestore Setup

The app uses Firestore for:

- meal sync
- daily goal persistence
- notification preference persistence
- app configuration
- backend usage tracking

Deploy the rules in the repo root:

```bash
firebase deploy --only firestore:rules
```

## Current Runtime Behavior

- iOS defaults to the Firebase-backed flow via `Constants.API.useFirebase = true`
- the website is deployed from `web/` via Firebase Hosting
- meal logging goes through Firebase Functions
- meals are stored locally in SwiftData
- signed-in users sync meals to Firestore
- the app fetches remote app configuration from Firestore

## Known Setup Footguns

- Older Firebase docs in this folder reference config patterns that have since changed
- Some docs describe anonymous auth as the primary user path, but current app startup prefers full sign-in
- The repo currently includes generated artifacts such as `functions/node_modules` and `android/app/build`

## Recommended Verification

After setup, verify these flows:

1. App launches without missing Firebase/package errors
2. Sign-in screen appears and sign-in succeeds
3. Logging a meal returns an AI result
4. A meal is saved locally
5. Signed-in user data appears in Firestore
6. `cd web && npm run build` succeeds and produces `web/out`
