# Analytics Events Reference

This document lists all analytics events tracked in the LogCal app. There are **19 events** total, organized into 5 categories.

---

## Event Categories Overview

- **Authentication** (4 events) - User sign up, login, logout, and account deletion
- **Meal Logging** (4 events) - Meal creation, editing, deletion, and failures
- **Navigation** (2 events) - Tab changes and view openings
- **Feature Usage** (5 events) - Speech recognition, date picker, meal type changes, daily goal updates
- **User Engagement** (4 events) - Meal summaries, detail views, help/FAQ, theme changes

---

## 1. Authentication Events (4 events)

### `user_signup`
- **When:** Fired when a new user signs up via Google or Apple Sign-In
- **Parameters:**
  - `method` (String): "google" or "apple"
- **Tracked in:** `AuthViewModel.swift`
- **Implementation:** Automatically detects if user is new via `authResult.additionalUserInfo?.isNewUser`

### `user_login`
- **When:** Fired when an existing user signs in via Google or Apple Sign-In
- **Parameters:**
  - `method` (String): "google" or "apple"
- **Tracked in:** `AuthViewModel.swift`
- **Implementation:** Triggered in `signInWithGoogle()` and `handleAppleSignIn()` methods

### `user_logout`
- **When:** Fired when user signs out
- **Parameters:** None
- **Tracked in:** `AuthViewModel.swift`
- **Implementation:** Triggered in `signOut()` method

### `account_deleted`
- **When:** Fired when user deletes their account
- **Parameters:** None
- **Tracked in:** `AuthViewModel.swift`
- **Implementation:** Triggered in `deleteAccount()` method

---

## 2. Meal Logging Events (4 events)

### `meal_logged`
- **When:** Fired when a meal is successfully logged
- **Parameters:**
  - `meal_type` (String): "breakfast", "lunch", "dinner", or "snack"
  - `total_calories` (Double): Total calories in the meal
  - `item_count` (Int): Number of food items in the meal
- **Tracked in:** `LogViewModel.swift`
- **Implementation:** Tracked after successful API response and local save

### `meal_log_failed`
- **When:** Fired when meal logging fails
- **Parameters:**
  - `error_type` (String): Description of the error that occurred
- **Tracked in:** `LogViewModel.swift`
- **Implementation:** Tracked in the catch block when API call fails

### `meal_edited`
- **When:** Fired when user saves changes to a meal
- **Parameters:** None
- **Tracked in:** `MealEditView.swift`
- **Implementation:** Triggered in `saveChanges()` method

### `meal_deleted`
- **When:** Fired when user deletes a meal
- **Parameters:** None
- **Tracked in:** `MealEditView.swift`
- **Implementation:** Triggered in `deleteMeal()` method

---

## 3. Navigation Events (2 events)

### `tab_changed`
- **When:** Fired when user switches between tabs
- **Parameters:**
  - `tab_name` (String): "Dashboard", "Log", "History", or "Profile"
- **Tracked in:** `logcalApp.swift`
- **Implementation:** Tracked via `.onChange(of: selectedTab)` when tab selection changes

### `view_opened`
- **When:** Fired when a view appears on screen
- **Parameters:**
  - `view_name` (String): Name of the view ("Dashboard", "Log", "History", "Profile")
- **Tracked in:** Multiple files:
  - `logcalApp.swift` - For tab views
  - `HomeView.swift` - For Log view
  - `MealDetailView.swift` - For meal detail view
  - `HelpFAQView.swift` - For Help & FAQ view
- **Implementation:** Tracked via `.onAppear` modifier on each view

---

## 4. Feature Usage Events (5 events)

### `speech_recognition_started`
- **When:** Fired when user taps microphone button to start voice input
- **Parameters:** None
- **Tracked in:** `LogViewModel.swift`
- **Implementation:** Triggered in `toggleSpeechRecognition()` method when mic starts

### `speech_recognition_stopped`
- **When:** Fired when user stops voice input
- **Parameters:** None
- **Tracked in:** `LogViewModel.swift`
- **Implementation:** Triggered in `toggleSpeechRecognition()` method when mic stops

### `date_picker_opened`
- **When:** Fired when user taps date button to open date picker
- **Parameters:** None
- **Tracked in:** `HomeView.swift`
- **Implementation:** Triggered in date button action

### `meal_type_changed`
- **When:** Fired when user manually changes meal type (not auto-inferred)
- **Parameters:**
  - `meal_type` (String): Selected meal type ("breakfast", "lunch", "dinner", or "snack")
- **Tracked in:** `LogViewModel.swift`
- **Implementation:** Tracked in `handleMealTypeChange()` when user manually selects meal type

### `daily_goal_changed`
- **When:** Fired when user saves a new daily calorie goal
- **Parameters:**
  - `new_goal` (Double): New daily calorie goal (100-5000)
- **Tracked in:** `DailyGoalView.swift`
- **Implementation:** Triggered in "Save Goal" button action

---

## 5. User Engagement Events (4 events)

### `meal_summary_viewed`
- **When:** Fired when meal summary card appears after successful meal log
- **Parameters:** None
- **Tracked in:** `HomeView.swift`
- **Implementation:** Tracked via `.onAppear` on the result card

### `meal_detail_viewed`
- **When:** Fired when user opens meal detail view
- **Parameters:** None
- **Tracked in:** `MealDetailView.swift`
- **Implementation:** Tracked via `.onAppear` on `MealDetailView`

### `help_faq_opened`
- **When:** Fired when user opens Help & FAQ view
- **Parameters:** None
- **Tracked in:** `HelpFAQView.swift`
- **Implementation:** Tracked via `.onAppear` on `HelpFAQView`

### `theme_changed`
- **When:** Fired when user changes app theme
- **Parameters:**
  - `theme_name` (String): "system", "light", or "dark"
- **Tracked in:** `ThemeSelectorSheet.swift`
- **Implementation:** Tracked in each theme row's action closure when theme is selected

---

## Parameter Types Reference

### String Parameters
- **`method`**: "google" or "apple" - Authentication method used
- **`meal_type`**: "breakfast", "lunch", "dinner", or "snack" - Type of meal
- **`error_type`**: Error description text - Description of the error that occurred
- **`tab_name`**: "Dashboard", "Log", "History", or "Profile" - Name of the tab
- **`view_name`**: View identifier - Name of the view
- **`theme_name`**: "system", "light", or "dark" - Selected theme

### Numeric Parameters
- **`total_calories`**: Double - Total calories in the meal (any positive number)
- **`item_count`**: Int - Number of food items in the meal (any positive integer)
- **`new_goal`**: Double - New daily calorie goal (100-5000)

---

## Analytics Service Methods

All events are tracked through the `AnalyticsService` struct. Here are all available methods:

### Authentication Methods
- `AnalyticsService.trackSignUp(method: String)`
- `AnalyticsService.trackLogin(method: String)`
- `AnalyticsService.trackLogout()`
- `AnalyticsService.trackAccountDeleted()`

### Meal Logging Methods
- `AnalyticsService.trackMealLogged(mealType: String, totalCalories: Double, itemCount: Int)`
- `AnalyticsService.trackMealLogFailed(errorType: String)`
- `AnalyticsService.trackMealEdited()`
- `AnalyticsService.trackMealDeleted()`

### Navigation Methods
- `AnalyticsService.trackTabChanged(tabName: String)`
- `AnalyticsService.trackViewOpened(viewName: String)`

### Feature Usage Methods
- `AnalyticsService.trackSpeechRecognitionStarted()`
- `AnalyticsService.trackSpeechRecognitionStopped()`
- `AnalyticsService.trackDatePickerOpened()`
- `AnalyticsService.trackMealTypeChanged(mealType: String)`
- `AnalyticsService.trackDailyGoalChanged(newGoal: Double)`

### User Engagement Methods
- `AnalyticsService.trackMealSummaryViewed()`
- `AnalyticsService.trackMealDetailViewed()`
- `AnalyticsService.trackHelpFAQOpened()`
- `AnalyticsService.trackThemeChanged(themeName: String)`

---

## Where Events Are Tracked

### Service File
- **`logcal/Services/AnalyticsService.swift`** - Contains all event definitions (19 methods)

### View Models
- **`logcal/ViewModels/AuthViewModel.swift`** - Tracks 4 authentication events
- **`logcal/ViewModels/LogViewModel.swift`** - Tracks 5 events (meal logging, speech, meal type)

### Views
- **`logcal/logcalApp.swift`** - Tracks 2 events (tab changes, view opens)
- **`logcal/Views/HomeView.swift`** - Tracks 2 events (date picker, meal summary)
- **`logcal/Views/MealDetailView.swift`** - Tracks 1 event (meal detail view)
- **`logcal/Views/MealEditView.swift`** - Tracks 2 events (meal edit, delete)
- **`logcal/Views/DailyGoalView.swift`** - Tracks 1 event (daily goal change)
- **`logcal/Views/HelpFAQView.swift`** - Tracks 1 event (help/FAQ open)
- **`logcal/Views/ThemeSelectorSheet.swift`** - Tracks 1 event (theme change)

---

## Code Examples

### Example 1: Tracking Meal Log
```swift
// In LogViewModel.swift after successful meal log
AnalyticsService.trackMealLogged(
    mealType: response.mealType,
    totalCalories: response.totalCalories,
    itemCount: response.items.count
)
```

### Example 2: Tracking Authentication
```swift
// In AuthViewModel.swift after Google sign-in
let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
if isNewUser {
    AnalyticsService.trackSignUp(method: "google")
} else {
    AnalyticsService.trackLogin(method: "google")
}
```

### Example 3: Tracking Feature Usage
```swift
// In LogViewModel.swift when mic button is tapped
AnalyticsService.trackSpeechRecognitionStarted()
```

---

## Viewing Events in Firebase Console

### Location
Navigate to: **Firebase Console** → **Analytics** → **Events**

### Views Available
- **All events** - Historical data showing all events over time
- **Real-time** - Live events as they happen (useful for testing, shows within ~30 seconds)

### What You'll See
- Event count (how many times the event occurred)
- Parameter values and their distributions
- User count (unique users who triggered the event)
- Event value (if applicable)

### Additional Metrics
- **User engagement** section - Aggregated metrics like daily/weekly active users
- **Retention** - User retention over time

---

## Important Notes

- All events include debug logging in development mode (look for `DEBUG: [Analytics]` in console)
- Events are automatically sent to Firebase Analytics
- No PII (Personally Identifiable Information) is tracked
- User IDs are anonymized by Firebase Analytics automatically
- Events may take a few minutes to appear in Firebase Console (except real-time view)
- Real-time view shows events within ~30 seconds
- Historical data is aggregated hourly/daily
