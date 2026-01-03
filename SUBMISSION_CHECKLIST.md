# App Store Submission Checklist - Current Status

## ✅ Completed (Ready)

- [x] Privacy Manifest (`PrivacyInfo.xcprivacy`)
- [x] Launch Screen (Storyboard)
- [x] App Icon
- [x] Bundle ID: `com.serene.logcal`
- [x] Privacy Policy HTML file exists
- [x] Usage descriptions (microphone, speech recognition)
- [x] Sign in with Apple entitlements
- [x] Version: 1.0 (Build: 1)
- [x] iOS 17.6 minimum deployment target
- [x] Daily goal Firestore sync implemented
- [x] App version check system implemented
- [x] Toast notification system
- [x] Help & FAQ with expandable questions

---

## 🔴 Critical - Must Complete Before Submission

### 1. Deploy Firestore Rules ⚠️ **REQUIRED**
**Status**: Rules updated but need deployment

**Action**: Deploy updated Firestore rules that include:
- `users/{userId}` document access (for daily goal)
- `app/config` public read access (for version check)

```bash
firebase deploy --only firestore:rules
```

**Why**: Without this, daily goal sync and app config won't work.

---

### 2. Create App in App Store Connect ⚠️ **REQUIRED**
**Status**: Not started

**Steps**:
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: **iOS**
   - Name: **LogCal**
   - Primary Language: **English**
   - Bundle ID: **com.serene.logcal** (must match exactly)
   - SKU: **logcal-001** (or any unique identifier)

**Time**: 15-20 minutes

---

### 3. Host Privacy Policy ⚠️ **REQUIRED**
**Status**: File exists but not hosted

**Options** (choose one):
- **GitHub Pages** (free, easiest)
- **Firebase Hosting** (free, already using Firebase)
- **Your own website**

**Action**: 
1. Upload `privacypolicy.html` to hosting service
2. Get the public URL
3. Add URL to App Store Connect

**Time**: 15-30 minutes

**Current URL**: `https://sites.google.com/view/privacypolicylogcalai/home` (already exists!)

---

### 4. App Screenshots ⚠️ **REQUIRED**
**Status**: Missing

**Required Sizes** (minimum 1 per size):
- iPhone 6.7": 1290 x 2796 pixels
- iPhone 6.5": 1242 x 2688 pixels  
- iPhone 5.5": 1242 x 2208 pixels
- iPad Pro 12.9": 2048 x 2732 pixels (optional)

**What to Capture**:
1. Dashboard/Home screen
2. Meal logging interface (with voice input visible)
3. History/Calendar view
4. Profile/Settings
5. Help & FAQ screen

**Time**: 1-2 hours

---

### 5. App Description & Metadata ⚠️ **REQUIRED**
**Status**: Needs writing

**Required Fields**:
- **Name**: LogCal (30 chars max)
- **Subtitle**: "AI-Powered Calorie Tracker" (30 chars max)
- **Description**: 4000 chars max
- **Keywords**: calorie, tracking, food, diet, health, fitness, meal, log, nutrition (100 chars max)
- **Category**: Health & Fitness
- **Age Rating**: Complete questionnaire (should be 4+)

**Time**: 30-45 minutes

---

### 6. Support URL ⚠️ **REQUIRED**
**Status**: Needs setup

**Options**:
- GitHub Issues page
- Email: support@yourdomain.com
- Contact form on website
- Firebase Hosting page

**Time**: 10-15 minutes

---

## 🟡 Important - Should Complete

### 7. Set Up Firestore App Config
**Status**: Code ready, needs Firestore document

**Action**: Create `app/config` document in Firestore:
```json
{
  "minimumAppVersion": "1.0",
  "updateMessage": null,
  "appStoreURL": null,
  "lastUpdated": <TIMESTAMP>
}
```

**Time**: 5 minutes

---

### 8. Final Testing Checklist
**Status**: Needs completion

**Test on Real Device** (not simulator):
- [ ] App launches without crashes
- [ ] Sign in with Google works
- [ ] Sign in with Apple works (on real device)
- [ ] Meal logging works
- [ ] Voice input works
- [ ] History view displays correctly
- [ ] Cloud sync works (meals sync across devices)
- [ ] Daily goal syncs across devices
- [ ] App handles offline mode gracefully
- [ ] Dark mode works correctly
- [ ] No console errors/warnings

**Time**: 2-3 hours

---

### 9. TestFlight Beta Testing (Recommended)
**Status**: Not started

**Steps**:
1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Wait for processing (10-30 minutes)
4. Add to TestFlight
5. Invite testers (friends, family)
6. Collect feedback

**Time**: 1 hour (plus waiting for processing)

---

## 🔵 Optional - Can Do Later

### 10. Debug Logs Cleanup (Optional)
**Status**: Many debug logs present

**Note**: Debug logs don't prevent submission, but cleaning them up is good practice.

**Options**:
- Remove all `print("DEBUG: ...")` statements
- Or wrap them in `#if DEBUG` conditionals
- Remove `DebugLogger` calls (or make them conditional)

**Time**: 30 minutes

---

### 11. App Store Optimization
- [ ] Promotional text (170 chars, optional)
- [ ] App preview video (optional)
- [ ] Marketing URL (optional)

---

## 📋 Build Preparation Checklist

### Before Archiving:

- [ ] **Deploy Firestore rules** (critical!)
- [ ] **Create app config in Firestore** (for version check)
- [ ] Verify version numbers: 1.0 (1)
- [ ] Test on release configuration
- [ ] Verify API keys are secure (in Keychain, not code)
- [ ] Test with fresh install (delete app, reinstall)
- [ ] Verify privacy policy URL is accessible

---

## ⏱️ Estimated Time to Ready

- **Minimum (just requirements)**: 3-4 hours
- **Recommended (with testing)**: 1-2 days
- **Polished (with TestFlight)**: 2-3 days

---

## 🎯 Priority Order

1. **Deploy Firestore Rules** (5 min) - ⬅️ **DO THIS FIRST**
2. **Create App Store Connect listing** (20 min)
3. **Host Privacy Policy** (15 min) - You already have a URL!
4. **Take Screenshots** (1-2 hours)
5. **Write App Description** (30 min)
6. **Set up Support URL** (15 min)
7. **Create Firestore app/config** (5 min)
8. **Final Testing** (2-3 hours)
9. **Upload to TestFlight** (1 hour + wait time)
10. **Submit for Review** (after testing complete)

---

## 🚨 Common Rejection Reasons to Avoid

1. ✅ Privacy Manifest - **DONE**
2. ⚠️ Missing Privacy Policy URL - **Need to add to App Store Connect**
3. ⚠️ Incomplete App Information - **Need screenshots and description**
4. ⚠️ Missing Support URL - **Need to add**
5. ✅ Usage Descriptions - **DONE**
6. ⚠️ Crashes on Launch - **Test thoroughly**
7. ⚠️ Export Compliance - **Answer when uploading build**

---

## Quick Wins (Can Do Now)

1. ✅ **Deploy Firestore Rules** - 5 minutes
2. ✅ **Create App Store Connect app** - 20 minutes (can do without screenshots)
3. ✅ **Add Privacy Policy URL** - Already have: `https://sites.google.com/view/privacypolicylogcalai/home`
4. ✅ **Create Firestore app/config** - 5 minutes

These can be done immediately and don't require screenshots or builds.

