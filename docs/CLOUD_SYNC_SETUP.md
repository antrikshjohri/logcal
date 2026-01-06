# Cloud Sync Setup Guide

## Overview

The app now syncs meal logs to Firebase Firestore, allowing users to access their data across devices and after reinstalling the app.

## How It Works

### Data Storage Structure

- **Local Storage**: SwiftData (for offline access and performance)
- **Cloud Storage**: Firestore (for cross-device sync and backup)
- **Structure**: `users/{userId}/meals/{mealId}`

### Sync Behavior

1. **On Meal Log**: Automatically saves to Firestore when user logs a meal
2. **On App Launch**: Fetches any new meals from Firestore and merges with local data
3. **On Sign-In**: Migrates all local meals to cloud, then fetches cloud data
4. **On Delete**: Deletes from both local storage and Firestore

### User Types

- **Anonymous Users**: Data stored locally only (no cloud sync)
- **Signed-In Users**: Data synced to Firestore automatically

## Setup Requirements

### 1. Enable Firestore in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/logcal-ai/firestore)
2. Click **"Firestore Database"** in the left sidebar
3. Click **"Create database"** (if not already created)
4. Choose **"Start in test mode"** (we'll update rules)
5. Select a location (choose closest to your users)
6. Click **"Enable"**

### 2. Deploy Firestore Security Rules

The security rules are in `firestore.rules`. Deploy them:

```bash
firebase deploy --only firestore:rules
```

Or manually update in Firebase Console:
1. Go to **Firestore Database** → **Rules** tab
2. Copy the rules from `firestore.rules`
3. Click **"Publish"**

### 3. Add FirebaseFirestore to Xcode Project

The Firebase iOS SDK should already include Firestore. To add it:

1. In Xcode, select your **project** (top of navigator, blue icon)
2. Select your **target** (under "TARGETS" - should be "logcal")
3. Go to **"Package Dependencies"** tab
4. Find **"firebase-ios-sdk"** in the list
5. Click on it to expand
6. You should see a list of products like:
   - ✅ FirebaseAuth
   - ✅ FirebaseCore
   - ✅ FirebaseFunctions
   - ✅ FirebaseStorage
   - ❌ FirebaseFirestore (might be unchecked)
7. Check the box next to **FirebaseFirestore**
8. Xcode will automatically update the project

**Alternative method if above doesn't work:**
1. In Xcode, go to **File** → **Add Packages...**
2. If you see "firebase-ios-sdk" already added, click on it
3. Click **"Add Package"** button
4. In the product selection screen, make sure **FirebaseFirestore** is checked
5. Click **"Add Package"**

### 4. Test Cloud Sync

1. Sign in with Google
2. Log a meal
3. Check Firebase Console → Firestore Database
4. You should see: `users/{userId}/meals/{mealId}` with your meal data

## Data Structure in Firestore

```
users/
  {userId}/
    meals/
      {mealId}/
        id: string (UUID)
        timestamp: timestamp
        createdAt: timestamp
        foodText: string
        mealType: string
        totalCalories: number
        rawResponseJson: string
```

## Security Rules

The Firestore rules ensure:
- Users can only read/write their own meals
- Anonymous users cannot access cloud data
- All other access is denied

See `firestore.rules` for the complete rules.

## Troubleshooting

### "No authenticated user, skipping Firestore save"
- User is anonymous - cloud sync only works for signed-in users
- Sign in with Google to enable cloud sync

### "Error saving meal to Firestore"
- Check Firestore is enabled in Firebase Console
- Verify security rules are deployed
- Check network connection

### Data not syncing
- Ensure user is signed in (not anonymous)
- Check Firebase Console for errors
- Verify Firestore is enabled and rules are deployed

## Migration

When a user signs in for the first time:
1. All local meals are migrated to Firestore
2. Any existing cloud meals are fetched and merged
3. Duplicates are avoided (based on meal ID)

## Offline Support

- Local data is always available (SwiftData)
- Cloud sync happens in background
- Failed syncs are logged but don't block the app

