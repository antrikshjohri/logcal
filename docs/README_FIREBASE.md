# Firebase Backend Integration

This app now uses Firebase Functions to securely proxy OpenAI API calls.

## Architecture

```
iOS App → Firebase Functions → OpenAI API
         ↓
    Firebase Auth (Anonymous)
         ↓
    Firestore (Usage tracking)
```

## Features

✅ **Secure API Key Storage** - OpenAI key stored in Firebase config, never exposed to clients  
✅ **Authentication** - Anonymous auth for quick setup (can upgrade to full auth later)  
✅ **Rate Limiting** - 10 requests/minute, 100 requests/day per user  
✅ **Usage Tracking** - Tracks API usage in Firestore  
✅ **Error Handling** - Proper error messages and recovery suggestions  

## Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or use existing)
3. Add an iOS app to your project
4. Download `GoogleService-Info.plist`
5. Add it to your Xcode project (drag into project navigator)

### 2. Install Firebase SDK

In Xcode:
1. File > Add Packages
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Select these products:
   - FirebaseAuth
   - FirebaseFunctions
   - FirebaseCore

### 3. Deploy Functions

```bash
# Install dependencies
cd functions
npm install

# Set OpenAI API key
firebase functions:config:set openai.api_key="your-openai-api-key"

# Deploy
firebase deploy --only functions
```

### 4. Configure App

The app is already configured to use Firebase by default. To switch back to direct OpenAI (for development):

Edit `logcal/Utils/Constants.swift`:
```swift
enum API {
    static let useFirebase = false // Set to false for direct OpenAI
}
```

## How It Works

1. **App Launch**: Firebase initializes, user signs in anonymously
2. **Log Meal**: App calls Firebase Function `logMeal`
3. **Function**: Verifies auth, checks rate limits, calls OpenAI
4. **Response**: Returns meal data to app
5. **Storage**: Meal saved locally in SwiftData (can migrate to Firestore later)

## Rate Limits

- **10 requests per minute** per user
- **100 requests per day** per user

Adjust in `functions/src/index.ts`:
```typescript
const MAX_REQUESTS_PER_DAY = 100;
const MAX_REQUESTS_PER_MINUTE = 10;
```

## Authentication

Currently uses **anonymous authentication** for simplicity. Users are automatically signed in on first use.

To upgrade to full authentication:
1. Add Firebase Auth UI or custom sign-in
2. Update `FirebaseService.signInAnonymously()` to use your auth method
3. Function already supports any Firebase Auth method

## Cost Estimation

**Firebase Functions:**
- Free tier: 2M invocations/month
- After: ~$0.40 per million
- Very cost-effective for most apps

**Firestore:**
- Free tier: 50K reads, 20K writes/day
- Minimal usage for rate limiting tracking

## Troubleshooting

### "Authentication required"
- Check Firebase is initialized in `logcalApp.swift`
- Verify `GoogleService-Info.plist` is added to project
- Check Firebase Auth is enabled in Firebase Console

### "Rate limit exceeded"
- User has hit daily/minute limits
- Adjust limits in `functions/src/index.ts` if needed

### Function not found
- Verify functions are deployed: `firebase functions:list`
- Check function name matches: `logMeal`

## Next Steps

1. ✅ Firebase Functions deployed
2. ✅ iOS app updated
3. 🔄 Add full Firebase Auth (email/password, Google, etc.)
4. 🔄 Migrate to Firestore for cloud sync
5. 🔄 Add user profiles and settings

## Development vs Production

- **Development**: Set `useFirebase = false` to use direct OpenAI
- **Production**: Set `useFirebase = true` to use Firebase Functions

This allows easy switching between modes during development.

