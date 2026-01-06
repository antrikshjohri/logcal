# Quick Start Guide - Firebase Backend

## 5-Minute Setup

### Step 1: Firebase Console Setup (2 min)
1. Go to https://console.firebase.google.com/
2. Create new project: "logcal" (or your name)
3. Add iOS app:
   - Bundle ID: Check your Xcode project settings
   - Download `GoogleService-Info.plist`
   - Add to Xcode project (drag into project navigator)

### Step 2: Install Firebase CLI (1 min)
```bash
npm install -g firebase-tools
firebase login
```

### Step 3: Deploy Functions (2 min)
```bash
cd functions
npm install


# Set OpenAI API key as a secret
firebase functions:secrets:set OPENAI_API_KEY
# When prompted, paste your OpenAI API key

npm run build
firebase deploy --only functions
```

**Note:** Make sure `.firebaserc` has your actual project ID, not "your-project-id"

### Step 4: Add Firebase SDK to Xcode (1 min)
1. File > Add Packages
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select: FirebaseAuth, FirebaseFunctions, FirebaseCore
4. Click "Add Package"

### Step 5: Build & Run
The app is already configured! Just build and run.

## Verify It Works

1. Open app
2. Enter a meal description
3. Tap "Log Meal"
4. Should work! (Uses Firebase Functions)

## Switch to Direct OpenAI (Development)

If you want to test with direct OpenAI (bypasses Firebase):

Edit `logcal/Utils/Constants.swift`:
```swift
static let useFirebase = false
```

## Troubleshooting

**"Authentication required"**
- Make sure `GoogleService-Info.plist` is in your Xcode project
- Check Firebase is initialized in `logcalApp.swift`

**"Function not found"**
- Verify deployment: `firebase functions:list`
- Check you're using the correct Firebase project

**"OpenAI API key not configured"**
- Run: `firebase functions:config:get`
- Should show: `openai.api_key`

## What's Included

✅ Firebase Functions with rate limiting  
✅ Anonymous authentication  
✅ Secure API key storage  
✅ Error handling  
✅ Usage tracking  

## Next Steps

- Add email/password authentication
- Migrate to Firestore for cloud sync
- Add user profiles

