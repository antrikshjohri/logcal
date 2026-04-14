# Quick Google Sign-In Setup

## 5-Minute Setup

### Step 1: Add Google Sign-In SDK (2 min)

In Xcode:
1. **File** → **Add Packages**
2. URL: `https://github.com/google/GoogleSignIn-iOS`
3. Version: **Up to Next Major Version** (7.0.0)
4. Click **Add Package**
5. Select **GoogleSignIn** product
6. Click **Add Package**

### Step 2: Enable Google Sign-In in Firebase (1 min)

1. Go to: https://console.firebase.google.com/project/logcal-ai/authentication/providers
2. Click **"Google"**
3. Toggle **"Enable"** ON
4. Enter your **support email**
5. Click **"Save"**

### Step 3: Configure URL Scheme (1 min)

1. In Xcode, select your **project** (top of navigator)
2. Select your **target**
3. Go to **Info** tab
4. Under **URL Types**, click **+**
5. Add **URL Scheme**: 
   - Get value from `GoogleService-Info.plist` → `REVERSED_CLIENT_ID`
   - Example: `com.googleusercontent.apps.123456789-abcdefg`

### Step 4: Test!

1. Build and run
2. You should see sign-in screen on first launch
3. Try signing in with Google or Apple
4. Should see "Welcome [Name]" in Log screen

## That's It! 🎉

The app now supports:
- ✅ Google Sign-In
- ✅ Anonymous Sign-In (skip)

## Troubleshooting

**"Google Sign-In not configured"**
- Check `GoogleService-Info.plist` is in project
- Verify URL scheme is added

**Sign-in screen not showing**
- Check Firebase providers are enabled
- Verify SDK is added to project

