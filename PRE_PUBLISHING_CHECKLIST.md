# Pre-Publishing Checklist for LogCal

Complete checklist of everything needed before submitting to the App Store.

## ✅ Already Completed

- [x] Launch screen configured
- [x] App icon (light/dark mode versions)
- [x] Bundle ID: `com.serene.logcal`
- [x] Privacy policy HTML file exists
- [x] Usage descriptions for microphone and speech recognition
- [x] Sign in with Apple entitlements
- [x] Version numbers: 1.0 (1)
- [x] **Privacy Manifest created and verified** ✅

---

## 🔴 Critical Requirements (Must Do)

### 1. Privacy Manifest (REQUIRED for iOS 17+)

**Status**: ✅ **COMPLETED**

Apple requires a Privacy Manifest file for apps using certain APIs or collecting data.

**Completed**:
- ✅ Created `PrivacyInfo.xcprivacy` file
- ✅ Declared all data collection types
- ✅ Added Required Reason APIs
- ✅ Added to Xcode project
- ✅ Build verified working

### 2. App Store Connect Setup

**Status**: ❌ Not started

1. **Create App in App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com/)
   - Click **My Apps** → **+** → **New App**
   - Fill in:
     - Platform: iOS
     - Name: LogCal
     - Primary Language: English
     - Bundle ID: `com.serene.logcal` (must match exactly)
     - SKU: `logcal-001` (or any unique identifier)

2. **App Information**
   - Category: Health & Fitness
   - Subcategory: (optional)
   - Privacy Policy URL: (you'll need to host `privacypolicy.html`)

3. **Age Rating**
   - Complete the questionnaire
   - Your app should be rated: **4+** (no objectionable content)

### 3. Export Compliance

**Status**: ⚠️ Needs verification

Apple requires export compliance information.

**Action**: When uploading build, answer:
- **Does your app use encryption?** → **Yes** (Firebase uses HTTPS)
- **Is your app exempt?** → **Yes** (using standard encryption for HTTPS)

### 4. Privacy Policy URL

**Status**: ⚠️ Needs hosting

You have `privacypolicy.html` but need to host it online.

**Options**:
- GitHub Pages (free)
- Firebase Hosting (free)
- Your own website
- Any static hosting service

**Action**: Host the file and add URL to App Store Connect

---

## 🟡 Important (Should Do)

### 5. App Screenshots

**Status**: ❌ Missing

Required for App Store listing.

**Required Sizes**:
- iPhone 6.7" (iPhone 14 Pro Max, 15 Pro Max): 1290 x 2796 pixels
- iPhone 6.5" (iPhone 11 Pro Max, XS Max): 1242 x 2688 pixels
- iPhone 5.5" (iPhone 8 Plus): 1242 x 2208 pixels
- iPad Pro 12.9": 2048 x 2732 pixels

**Minimum**: 1 screenshot per device size
**Recommended**: 3-5 screenshots showing key features

**What to show**:
1. Main dashboard/home screen
2. Meal logging interface
3. History/calendar view
4. Profile/settings
5. Voice input feature

### 6. App Preview Video (Optional but Recommended)

**Status**: ❌ Not created

Short video (15-30 seconds) showing app in action.

### 7. App Description

**Status**: ⚠️ Needs writing

Write compelling description for App Store:
- What the app does
- Key features
- Who it's for
- Why users should download it

**Character limits**:
- Name: 30 characters
- Subtitle: 30 characters
- Description: 4000 characters
- Keywords: 100 characters (comma-separated)

**Suggested Keywords**: calorie, tracking, food, diet, health, fitness, meal, log, nutrition

### 8. Support URL

**Status**: ⚠️ Needs setup

URL where users can get help/support.

**Options**:
- GitHub Issues page
- Email support
- Website contact form
- Firebase Hosting page

### 9. Marketing URL (Optional)

**Status**: ⚠️ Optional

Website for your app (optional but recommended).

---

## 🟢 Testing & Quality Assurance

### 10. Final Testing Checklist

**Status**: ⚠️ Needs completion

Test on **real devices** (not just simulator):

- [ ] App launches without crashes
- [ ] Sign in with Google works
- [ ] Sign in with Apple works (on real device)
- [ ] Meal logging works
- [ ] Voice input works
- [ ] History view displays correctly
- [ ] Cloud sync works
- [ ] App handles offline mode gracefully
- [ ] No memory leaks or performance issues
- [ ] App works on different iOS versions (minimum: iOS 18.6)
- [ ] App works on iPhone and iPad
- [ ] Dark mode works correctly
- [ ] All UI elements are accessible
- [ ] No console errors/warnings

### 11. TestFlight Beta Testing

**Status**: ⚠️ Recommended

1. Upload build to App Store Connect
2. Add internal testers (your team)
3. Add external testers (friends, family)
4. Collect feedback
5. Fix issues before public release

**Steps**:
1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Wait for processing (10-30 minutes)
4. Add to TestFlight
5. Invite testers

---

## 🔵 Nice to Have (Can Add Later)

### 12. App Store Optimization (ASO)

- [ ] App icon is recognizable and stands out
- [ ] Screenshots highlight key features
- [ ] Description uses relevant keywords
- [ ] App name is searchable
- [ ] Subtitle is descriptive

### 13. Localization

**Status**: ⚠️ English only (can add later)

Consider adding:
- Spanish
- French
- German
- Other languages based on target market

### 14. App Store Promotional Text

**Status**: ⚠️ Optional

Short text (170 characters) that appears above description.
Can be updated without new submission.

### 15. What's New in This Version

**Status**: ⚠️ For future updates

Release notes for version 1.0 (first release).

---

## 📋 Build & Submission Checklist

### Before Building for Release:

- [ ] Set build number (increment for each submission)
- [ ] Remove debug code/logs (or disable in release)
- [ ] Test on release configuration
- [ ] Verify all API keys are secure (not in code)
- [ ] Check Firebase rules are production-ready
- [ ] Verify privacy policy is accessible
- [ ] Test with fresh install (delete app, reinstall)

### Archive & Upload:

1. **In Xcode**:
   - Select **Any iOS Device** (not simulator)
   - Product → **Archive**
   - Wait for archive to complete
   - Click **Distribute App**
   - Select **App Store Connect**
   - Follow prompts

2. **In App Store Connect**:
   - Wait for processing (10-30 minutes)
   - Go to **TestFlight** tab
   - Test the build
   - When ready, go to **App Store** tab
   - Fill in all required information
   - Submit for review

### Submission Requirements:

- [ ] All required screenshots uploaded
- [ ] App description complete
- [ ] Privacy policy URL added
- [ ] Support URL added
- [ ] Age rating completed
- [ ] Export compliance answered
- [ ] App Store listing information complete
- [ ] Build selected for submission

---

## 🚨 Common Rejection Reasons to Avoid

1. **Missing Privacy Policy** - Must be accessible URL
2. **Incomplete App Information** - All fields must be filled
3. **Crashes on Launch** - Test thoroughly
4. **Missing Functionality** - App must work as described
5. **Privacy Manifest Issues** - Must declare data collection
6. **Incorrect Bundle ID** - Must match App Store Connect
7. **Missing Usage Descriptions** - Already have these ✅
8. **App Preview Issues** - If included, must work
9. **Guideline Violations** - Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 📝 Quick Start Priority Order

1. ✅ **Create Privacy Manifest** - **COMPLETED**
2. **Create App in App Store Connect** (30 minutes) - **NEXT PRIORITY** ⬅️
3. **Host Privacy Policy** (30 minutes) - REQUIRED
4. **Take Screenshots** (1-2 hours) - REQUIRED
5. **Write App Description** (30 minutes) - REQUIRED
6. **Test on Real Device** (ongoing) - CRITICAL
7. **Upload to TestFlight** (30 minutes) - RECOMMENDED
8. **Submit for Review** (after testing complete)

---

## Estimated Time to Ready

- **Minimum viable**: 4-6 hours
- **Recommended (with testing)**: 1-2 days
- **Polished (with screenshots, testing, optimization)**: 3-5 days

---

## Next Steps

✅ **Privacy Manifest** - COMPLETED!

**Your Next Priority Tasks:**

1. **App Store Connect Setup** (30 min) - Create your app listing
2. **Host Privacy Policy** (30 min) - Upload `privacypolicy.html` online
3. **Take Screenshots** (1-2 hours) - Required for submission
4. **Write App Description** (30 min) - Marketing copy for App Store
5. **Final Testing** (ongoing) - Test on real devices

**Recommended Order:**
1. Set up App Store Connect (can do this now, even without screenshots)
2. Host privacy policy (quick win - can use GitHub Pages or Firebase Hosting)
3. Take screenshots (do this while App Store Connect processes)
4. Write description (can refine later)
5. Test and upload to TestFlight

