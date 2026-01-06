# Firebase Backend Setup Guide

This guide will help you set up the Firebase backend for the LogCal app.

## Prerequisites

1. Node.js 18+ installed
2. Firebase CLI installed: `npm install -g firebase-tools`
3. A Firebase project created at [Firebase Console](https://console.firebase.google.com/)

## Step 1: Install Dependencies

```bash
cd functions
npm install
```

## Step 2: Configure Firebase Project

1. Login to Firebase CLI:
```bash
firebase login
```

2. Initialize Firebase (if not already done):
```bash
firebase init
```
   - Select: Functions, Firestore
   - Use existing project or create new
   - Choose TypeScript
   - Use ESLint: Yes
   - Install dependencies: Yes

3. Update `.firebaserc` with your project ID:
```json
{
  "projects": {
    "default": "your-actual-project-id"
  }
}
```

## Step 3: Set OpenAI API Key

Set your OpenAI API key as a Firebase Secret (recommended method):

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

When prompted, paste your OpenAI API key. This securely stores it in Firebase Secret Manager.

**Alternative (for local development):**
You can also set it as an environment variable in `functions/.env`:
```
OPENAI_API_KEY=your-key-here
```

**Important:** Never commit your API key to git!

## Step 4: Build Functions

```bash
cd functions
npm run build
```

## Step 5: Deploy Functions

```bash
firebase deploy --only functions
```

This will deploy:
- `logMeal` - Main function to log meals (requires auth)
- `healthCheck` - Health check endpoint (no auth)

## Step 6: Get Function URLs

After deployment, you'll see URLs like:
```
✔  functions[logMeal(us-central1)] Successful create operation.
✔  functions[healthCheck(us-central1)] Successful create operation.
```

The `logMeal` function will be available as a callable function (not HTTP URL).

## Step 7: Configure iOS App

1. Add Firebase SDK to your iOS project:
   - In Xcode, go to File > Add Packages
   - Add: `https://github.com/firebase/firebase-ios-sdk`
   - Select: FirebaseAuth, FirebaseFunctions, FirebaseFirestore

2. Add `GoogleService-Info.plist`:
   - Download from Firebase Console > Project Settings > iOS App
   - Add to your Xcode project

3. Update the iOS app code (see next section)

## Testing

### Test Health Check (No Auth Required)
```bash
curl https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/healthCheck
```

### Test Log Meal (Requires Auth Token)
Use the iOS app or test with Firebase Functions emulator.

## Local Development

Run Firebase emulators locally:

```bash
cd functions
npm run serve
```

This starts the emulator on `http://localhost:5001`

## Rate Limiting

The function includes rate limiting:
- **10 requests per minute** per user
- **100 requests per day** per user

Adjust these in `functions/src/index.ts`:
```typescript
const MAX_REQUESTS_PER_DAY = 100;
const MAX_REQUESTS_PER_MINUTE = 10;
```

## Security

- ✅ API key stored securely in Firebase config
- ✅ Authentication required for meal logging
- ✅ Rate limiting to prevent abuse
- ✅ Firestore rules enforce user data isolation

## Troubleshooting

### "OpenAI API key not configured"
Run: `firebase functions:config:get` to verify config is set.

### "User must be authenticated"
Make sure Firebase Auth is set up in your iOS app.

### Function deployment fails
- Check Node.js version: `node --version` (should be 18+)
- Run `npm run build` in functions directory first
- Check Firebase CLI is up to date: `firebase --version`

## Next Steps

1. Set up Firebase Authentication in iOS app
2. Update `OpenAIService` to call Firebase Functions
3. Optionally migrate to Firestore for cloud sync

