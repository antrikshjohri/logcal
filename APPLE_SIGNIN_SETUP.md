# Apple Sign-In Setup Guide

Complete step-by-step guide to enable Sign in with Apple for LogCal app.

## Prerequisites

- ✅ Paid Apple Developer Program membership ($99/year)
- ✅ Bundle ID: `com.serene.logcal`
- ✅ Xcode project with Sign in with Apple capability enabled
- ✅ Firebase project set up

---

## Part 1: Apple Developer Site Configuration

### Step 1: Create/Configure App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** in the left sidebar
4. Click the **+** button to create a new identifier (or find existing `com.serene.logcal`)

#### If creating new App ID:
- **Description**: LogCal App
- **Bundle ID**: Select **Explicit** → Enter: `com.serene.logcal`
- Click **Continue** → **Register**

#### If App ID already exists:
- Click on `com.serene.logcal` to edit it

### Step 2: Enable Sign in with Apple Service

1. In your App ID configuration page, find **Capabilities** section
2. Check the box for **Sign In with Apple**
3. Click **Save** (or **Continue** → **Register** if creating new)

### Step 3: Create Service ID (for Web/Backend - Optional but Recommended)

**Note**: This is mainly for web apps, but some Firebase configurations may need it.

1. Go back to **Identifiers**
2. Click **+** → Select **Services IDs** → **Continue**
3. **Description**: LogCal Apple Sign-In Service
4. **Identifier**: `com.serene.logcal.signin` (or similar)
5. Click **Continue** → **Register**
6. Check **Sign In with Apple** → **Configure**
7. **Primary App ID**: Select `com.serene.logcal`
8. **Website URLs**:
   - **Domains**: `logcal-ai.firebaseapp.com` (or your Firebase domain)
   - **Return URLs**: `https://logcal-ai.firebaseapp.com/__/auth/handler`
9. Click **Save** → **Continue** → **Save**

---

## Part 2: Firebase Console Configuration

### Step 1: Enable Apple Sign-In Provider

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **logcal-ai**
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Apple** in the providers list
5. Click **Apple** → Toggle **Enable**
6. Click **Save**

### Step 2: Configure Apple Sign-In (if prompted)

Firebase may ask for:
- **Services ID**: Use the Service ID you created (e.g., `com.serene.logcal.signin`)
- **Apple Team ID**: Found in Apple Developer account (top right corner)
- **Key ID**: Not needed for iOS apps (only for web)
- **Private Key**: Not needed for iOS apps (only for web)

**For iOS apps**, Firebase typically doesn't require additional configuration beyond enabling the provider.

### Step 3: Verify OAuth Redirect URLs

1. In Firebase Console → **Authentication** → **Settings** → **Authorized domains**
2. Ensure your domains are listed:
   - `logcal-ai.firebaseapp.com`
   - `logcal-ai.web.app`
   - Your custom domain (if any)

---

## Part 3: Xcode Project Verification

### Step 1: Verify Bundle ID

1. Open project in Xcode
2. Select project in navigator → Select **logcal** target
3. Go to **General** tab
4. Verify **Bundle Identifier**: `com.serene.logcal`

### Step 2: Verify Signing & Capabilities

1. In Xcode, go to **Signing & Capabilities** tab
2. Verify:
   - ✅ **Team**: Your Apple Developer team selected
   - ✅ **Bundle Identifier**: `com.serene.logcal`
   - ✅ **Sign in with Apple** capability is present

#### If Sign in with Apple capability is missing:
1. Click **+ Capability**
2. Search for **Sign In with Apple**
3. Add it

### Step 3: Verify Entitlements File

Check `logcal.entitlements` contains:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

---

## Part 4: Testing

### Important Notes:

1. **Real Device Required**: Sign in with Apple **does NOT work** in iOS Simulator. You must test on a real device.

2. **Test Account**: 
   - Use a real Apple ID (not a test account)
   - Or create a test account in Apple Developer portal

3. **First Time Setup**:
   - On first sign-in, user will see Apple's consent screen
   - User can choose to share/hide email
   - User can choose to share/hide name

### Testing Steps:

1. Build and run on a **real iOS device** (not simulator)
2. Tap **Sign in with Apple** button
3. Authenticate with Face ID/Touch ID/Passcode
4. Choose email sharing preference
5. Verify successful sign-in

---

## Troubleshooting

### Error: -7026 "MCPasscodeManager passcode set check is not supported"
- **Cause**: Testing on simulator or device without passcode
- **Fix**: Test on real device with passcode/Face ID enabled

### Error: 1000 "AuthorizationError"
- **Cause**: App not properly configured in Apple Developer
- **Fix**: 
  1. Verify App ID has Sign in with Apple enabled
  2. Verify bundle ID matches exactly: `com.serene.logcal`
  3. Verify Xcode signing uses correct team

### Error: "Sign in with Apple is not available"
- **Cause**: Capability not enabled or wrong bundle ID
- **Fix**: 
  1. Check entitlements file
  2. Verify App ID configuration
  3. Clean build folder (Cmd+Shift+K) and rebuild

### Firebase Error: "Invalid credential"
- **Cause**: Apple ID token not properly formatted
- **Fix**: Verify code is using `OAuthProvider.appleCredential()` correctly

---

## Code Verification

Your current implementation looks correct. The key parts are:

1. ✅ **Entitlements**: Sign in with Apple capability enabled
2. ✅ **AuthView**: Apple Sign-In button and handler
3. ✅ **AuthViewModel**: `handleAppleSignIn()` method using Firebase
4. ✅ **Delegates**: Properly implemented ASAuthorizationControllerDelegate

---

## Next Steps After Setup

1. Test on real device
2. Verify user data in Firebase Console → Authentication → Users
3. Check that user email/name is stored correctly
4. Test sign-out and sign-in again

---

## Resources

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Apple Auth Guide](https://firebase.google.com/docs/auth/ios/apple)
- [Apple Developer Portal](https://developer.apple.com/account/)

