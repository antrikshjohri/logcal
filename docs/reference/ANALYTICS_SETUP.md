# Analytics Tracking Setup Guide

## Overview

Analytics tracking has been implemented throughout the app to track user behavior, feature usage, and engagement metrics. All events are logged to Firebase Analytics.

## Implementation Status

✅ **AnalyticsService** - Centralized service for tracking events  
✅ **Firebase Analytics Integration** - Ready to use (requires adding FirebaseAnalytics package)  
✅ **Event Tracking** - Implemented across all major touchpoints

## Step 1: Add Firebase Analytics SDK

Since Firebase Analytics is not yet added to the project, you need to add it:

1. **Open Xcode**
2. Select your project in the Project Navigator (top-level item)
3. Select your target (`logcal`) under "TARGETS"
4. Go to the **"Package Dependencies"** tab
5. Find `firebase-ios-sdk` in the list
6. Click the **"+"** button next to it (or click on it to expand)
7. Check the box for **"FirebaseAnalytics"**
8. Click **"Add Package"** or the package should update automatically

Alternatively, if the package is not showing FirebaseAnalytics:
1. Go to **File** → **Add Package Dependencies...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select **"FirebaseAnalytics"** product
4. Click **"Add Package"**

## Step 2: Verify Setup

After adding FirebaseAnalytics, the app should build successfully. The analytics are already initialized in `logcalApp.swift`:

```swift
import FirebaseAnalytics
// Analytics is automatically initialized with FirebaseApp.configure()
```

## Tracked Events

### Authentication Events
- `user_signup` - User signs up (parameters: `method` - "google" or "apple")
- `user_login` - User signs in (parameters: `method` - "google" or "apple")
- `user_logout` - User signs out
- `account_deleted` - User deletes account

### Meal Logging Events
- `meal_logged` - Successful meal log (parameters: `meal_type`, `total_calories`, `item_count`)
- `meal_log_failed` - Failed meal log (parameters: `error_type`)
- `meal_edited` - User edits a meal
- `meal_deleted` - User deletes a meal

### Navigation Events
- `tab_changed` - Tab switch (parameters: `tab_name` - "Dashboard", "Log", "History", "Profile")
- `view_opened` - View opened (parameters: `view_name`)

### Feature Usage Events
- `speech_recognition_started` - Mic button tapped
- `speech_recognition_stopped` - Mic stopped
- `date_picker_opened` - Date picker opened
- `meal_type_changed` - Meal type changed manually (parameters: `meal_type`)
- `daily_goal_changed` - Daily goal updated (parameters: `new_goal`)

### User Engagement Events
- `meal_summary_viewed` - Meal summary card displayed
- `meal_detail_viewed` - Meal detail view opened
- `help_faq_opened` - Help/FAQ opened
- `theme_changed` - Theme changed (parameters: `theme_name` - "system", "light", "dark")

## Where to View Analytics

### Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`logcal-ai`)
3. Click **"Analytics"** in the left sidebar
4. Navigate to **"Events"** to see all tracked events

### Real-Time Events

- **Firebase Console** → **Analytics** → **Events** → **Real-time** tab
- Shows events as they happen (useful for testing)

### Historical Data

- **Firebase Console** → **Analytics** → **Events** → **All events** tab
- View event counts, parameters, and trends over time

### User Engagement

- **Firebase Console** → **Analytics** → **User engagement**
- See daily/weekly active users, retention, and engagement metrics

## Debug Logging

During development, all analytics events are logged to the console with the prefix `DEBUG: [Analytics]`:

```
DEBUG: [Analytics] Event: meal_logged
DEBUG: [Analytics] Parameters: ["meal_type": "breakfast", "total_calories": 450.0, "item_count": 2]
```

This helps verify that events are being tracked correctly during development.

## Privacy Considerations

- ✅ No PII (Personally Identifiable Information) is tracked
- ✅ Only aggregate data (meal types, calories, feature usage)
- ✅ Complies with Firebase Analytics privacy guidelines
- ✅ User IDs are anonymized by Firebase Analytics automatically

## Testing Analytics

1. **Run the app** in Xcode
2. **Perform actions** (log meals, change tabs, etc.)
3. **Check console logs** for `DEBUG: [Analytics]` messages
4. **View Firebase Console** → **Analytics** → **Events** → **Real-time** to see events appear

## Notes

- Events may take a few minutes to appear in Firebase Console (not instant)
- Real-time view shows events within ~30 seconds
- Historical data is aggregated hourly/daily
- Firebase Analytics has a free tier with generous limits

