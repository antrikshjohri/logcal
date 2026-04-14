# Google Sign-In Setup Guide

This guide explains how to enable Google Sign-In in Firebase.

## Overview

The app supports:
- ✅ **Google Sign-In** - Sign in with Google account
- ✅ **Anonymous Sign-In** - Skip authentication (default)

## Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/logcal-ai/authentication/providers)
2. Click **"Authentication"** → **"Sign-in method"** tab
3. Find **"Google"** in the list
4. Click on it
5. Toggle **"Enable"** to ON
6. Enter your **Support email** (your email address)
7. Click **"Save"**

**Note:** The OAuth client ID is automatically configured from your `GoogleService-Info.plist`.

## Step 2: Configure Google Sign-In in Xcode

### Add Google Sign-In SDK

1. In Xcode, go to **File** → **Add Packages**
2. Add: `https://github.com/google/GoogleSignIn-iOS`
3. Select version: **Latest** (or 7.0.0+)
4. Click **"Add Package"**
5. Select **GoogleSignIn** product
6. Click **"Add Package"**

### Update Info.plist

1. Open your `Info.plist` (or add to project settings)
2. Add URL Scheme for Google Sign-In:
   - Key: `CFBundleURLTypes`
   - Type: Array
   - Add item:
     - `CFBundleURLSchemes`: Array
     - Add item: Your **reversed client ID** from `GoogleService-Info.plist`
       - Example: `com.googleusercontent.apps.123456789-abcdefg`
       - Find it in `GoogleService-Info.plist` under `REVERSED_CLIENT_ID`

**Or add directly to project settings:**
1. Select your project in Xcode
2. Select your target
3. Go to **Info** tab
4. Under **URL Types**, click **+**
5. Add URL Scheme: Your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`

## Step 3: Update GoogleService-Info.plist

Make sure your `GoogleService-Info.plist` includes:
- `CLIENT_ID` - For Google Sign-In
- `REVERSED_CLIENT_ID` - For URL scheme

These should already be present if you downloaded the file from Firebase Console.

## Step 4: Test Sign-In

1. Build and run the app
2. On first launch, you should see the sign-in screen
3. Try signing in with Google
4. You should see "Welcome [Name]" at the top of the Log screen

## Troubleshooting

### "Google Sign-In not configured"
- Check `GoogleService-Info.plist` is in your Xcode project
- Verify `CLIENT_ID` exists in the plist
- Make sure URL scheme is configured

### "Sign-in button not showing"
- Check Firebase Console - is the provider enabled?
- Verify SDK is added to project
- Check console for error messages

## How It Works

1. **First Launch**: App shows `AuthView` with Google sign-in option
2. **User Choice**:
   - Sign in with Google → Gets user's name from profile
   - Tap X or "Continue without signing in" → Uses anonymous auth
3. **Welcome Message**: If signed in, shows "Welcome [Name]" in HomeView
4. **Persistence**: Sign-in state persists across app launches

## Code Structure

- **`AuthViewModel`**: Manages authentication state and Google sign-in
- **`AuthView`**: UI for sign-in with Google
- **`HomeView`**: Shows welcome message when signed in
- **`logcalApp`**: Shows `AuthView` on first launch if not signed in

## Next Steps

- Add email/password sign-in (optional)
- Add profile screen to view/edit user info
- Add sign-out option in settings

