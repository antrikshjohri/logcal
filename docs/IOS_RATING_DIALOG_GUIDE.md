# iOS Rating Dialog Integration Guide

## Overview

iOS provides `SKStoreReviewController` for in-app rating prompts. This shows the native App Store rating dialog without leaving your app.

## Key Guidelines

### ✅ DO:
- Show after positive user experiences (successful meal log, reaching a goal, etc.)
- Show after user has used the app multiple times (at least 3-5 sessions)
- Show at natural breakpoints in user flow
- Respect Apple's rate limiting (max 3 prompts per year per user)
- Track when you've shown it to avoid spamming

### ❌ DON'T:
- Show immediately on first launch
- Show after negative experiences (errors, failures)
- Show too frequently (Apple limits to 3 times per year)
- Show in response to user actions (button taps) - Apple may reject
- Show during critical workflows
- Show if user has already rated

## Implementation

### Step 1: Import StoreKit

```swift
import StoreKit
```

### Step 2: Create a Rating Service

Create `logcal/Services/RatingService.swift`:

```swift
import Foundation
import StoreKit

class RatingService {
    static let shared = RatingService()
    
    private let userDefaults = UserDefaults.standard
    private let mealLogCountKey = "mealLogCount"
    private let lastRatingRequestKey = "lastRatingRequestDate"
    private let hasRatedKey = "hasRatedApp"
    private let ratingRequestCountKey = "ratingRequestCount"
    
    // Minimum requirements before showing rating
    private let minMealLogs = 5 // User must log at least 5 meals
    private let minDaysSinceLastRequest = 90 // 90 days between requests
    private let maxRatingRequests = 3 // Apple's limit
    
    private init() {}
    
    /// Increment meal log count (call after successful meal log)
    func incrementMealLogCount() {
        let currentCount = userDefaults.integer(forKey: mealLogCountKey)
        userDefaults.set(currentCount + 1, forKey: mealLogCountKey)
    }
    
    /// Check if rating dialog should be shown
    func shouldShowRatingDialog() -> Bool {
        // Don't show if user already rated
        if userDefaults.bool(forKey: hasRatedKey) {
            return false
        }
        
        // Check if we've exceeded max requests
        let requestCount = userDefaults.integer(forKey: ratingRequestCountKey)
        if requestCount >= maxRatingRequests {
            return false
        }
        
        // Check minimum meal logs
        let mealLogCount = userDefaults.integer(forKey: mealLogCountKey)
        if mealLogCount < minMealLogs {
            return false
        }
        
        // Check time since last request
        if let lastRequestDate = userDefaults.object(forKey: lastRatingRequestKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            if daysSince < minDaysSinceLastRequest {
                return false
            }
        }
        
        // Show on milestone meal logs (5th, 10th, 20th, etc.)
        return mealLogCount == 5 || mealLogCount == 10 || mealLogCount == 20 || mealLogCount == 50
    }
    
    /// Request app rating (call when conditions are met)
    func requestRating() {
        guard shouldShowRatingDialog() else { return }
        
        // Update tracking
        userDefaults.set(Date(), forKey: lastRatingRequestKey)
        let requestCount = userDefaults.integer(forKey: ratingRequestCountKey)
        userDefaults.set(requestCount + 1, forKey: ratingRequestCountKey)
        
        // Request review (only works on real devices, not simulator)
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
    
    /// Mark that user has rated (call if you detect they rated)
    func markAsRated() {
        userDefaults.set(true, forKey: hasRatedKey)
    }
    
    /// Reset for testing (remove in production)
    func resetForTesting() {
        userDefaults.removeObject(forKey: mealLogCountKey)
        userDefaults.removeObject(forKey: lastRatingRequestKey)
        userDefaults.removeObject(forKey: hasRatedKey)
        userDefaults.removeObject(forKey: ratingRequestCountKey)
    }
}
```

### Step 3: Integrate in LogViewModel

In `logcal/ViewModels/LogViewModel.swift`, after successful meal log:

```swift
// After meal is successfully logged
RatingService.shared.incrementMealLogCount()

// Check and show rating dialog if appropriate
if RatingService.shared.shouldShowRatingDialog() {
    // Small delay to let success animation play
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        RatingService.shared.requestRating()
    }
}
```

### Step 4: Alternative - Show After Streak Milestone

In `logcal/Views/DashboardView.swift`, when user reaches a streak milestone:

```swift
// After checking streak
if streakCount == 7 || streakCount == 30 || streakCount == 100 {
    RatingService.shared.requestRating()
}
```

## Best Places to Show Rating Dialog

### ✅ Recommended Locations:

1. **After Successful Meal Log** (Best)
   - Location: `LogViewModel.swift` - after `logMeal()` succeeds
   - Trigger: After 5th, 10th, 20th, or 50th meal logged
   - Timing: 2 seconds after success animation

2. **After Reaching Streak Milestone**
   - Location: `DashboardView.swift` - when streak reaches 7, 30, or 100 days
   - Trigger: On view appear if milestone reached
   - Timing: After view loads

3. **After Completing Profile Setup**
   - Location: `EditProfileView.swift` - after saving profile
   - Trigger: First time user completes profile
   - Timing: After save success

### ❌ Avoid These Locations:

- On app launch
- After errors or failures
- During active workflows (typing, selecting)
- Immediately after user actions (button taps)
- In response to user gestures

## Testing

### Important Notes:
- **Rating dialog only appears on real devices** - not in simulator
- **Apple limits to 3 prompts per year** per user
- **Dialog may not appear** if user has already rated or if system decides not to show it
- **Test with resetForTesting()** method (remove in production)

### Testing Steps:
1. Reset rating state: `RatingService.shared.resetForTesting()`
2. Log 5 meals
3. On 5th meal log, rating dialog should appear (on real device)
4. Test timing and user experience

## Implementation Checklist

- [ ] Create `RatingService.swift`
- [ ] Import StoreKit in files that use it
- [ ] Add `incrementMealLogCount()` call after successful meal log
- [ ] Add rating request check after meal log (with delay)
- [ ] Test on real device (simulator won't show dialog)
- [ ] Remove `resetForTesting()` before production
- [ ] Consider adding analytics to track rating prompt appearances

## Additional Considerations

### Track Rating Prompt Events
Add analytics to track when rating dialog is shown:

```swift
AnalyticsService.trackRatingPromptShown()
```

### Handle User Actions
If user taps "Rate" in your custom prompt (before showing native dialog), you can:
- Open App Store directly: `UIApplication.shared.open(appStoreURL)`
- Or show native dialog: `SKStoreReviewController.requestReview()`

### Custom Rating Prompt (Optional)
You can show a custom prompt first, then show native dialog if user agrees:

```swift
// Show custom alert first
.alert("Enjoying LogCal?", isPresented: $showCustomRatingPrompt) {
    Button("Rate App") {
        RatingService.shared.requestRating()
    }
    Button("Not Now", role: .cancel) { }
} message: {
    Text("Your feedback helps us improve!")
}
```

## References

- [Apple Documentation](https://developer.apple.com/documentation/storekit/skstorereviewcontroller)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Section 2.5.1
