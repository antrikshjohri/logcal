# Enable Anonymous Authentication - Quick Fix

## The Error
```
CONFIGURATION_NOT_FOUND
Error Domain=FIRAuthErrorDomain Code=17999
```

This means **Anonymous Authentication is not enabled** in your Firebase project.

## Solution: Enable Anonymous Authentication

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/project/logcal-ai/authentication
2. Click on **"Authentication"** in the left sidebar
3. Click on the **"Sign-in method"** tab

### Step 2: Enable Anonymous Authentication
1. Scroll down to find **"Anonymous"** in the list of providers
2. Click on it
3. Toggle **"Enable"** to ON
4. Click **"Save"**

### Step 3: Test Again
Run your app again and try logging a meal. It should work now!

## Why This Happened
Firebase Authentication requires you to explicitly enable each sign-in method you want to use. Anonymous authentication is disabled by default for security reasons.

## Alternative: Use Email/Password Auth
If you prefer email/password authentication instead:
1. Enable "Email/Password" in Firebase Console
2. Update the code to use email/password sign-in instead of anonymous

But for now, enabling Anonymous is the quickest fix!

