# Testing iOS Rating Dialog

## Important Notes

⚠️ **The rating dialog ONLY appears on REAL DEVICES** - it will NOT show in the iOS Simulator.

⚠️ **Apple controls when the dialog actually appears** - even if you call `requestRating()`, Apple may choose not to show it if:
- User has already rated recently
- System decides it's not appropriate
- Too many requests have been made

## Testing Steps

### Step 1: Reset Rating State

Before testing, reset the rating state to start fresh:

**Option A: Add a temporary button in your app (for testing only)**

In `HomeView.swift` or `ProfileView.swift`, add a temporary debug button:

```swift
// TEMPORARY - Remove before production
Button("Reset Rating State (Testing)") {
    RatingService.shared.resetForTesting()
    print("DEBUG: Rating state reset")
}
```

**Option B: Use Xcode Debugger**

1. Set a breakpoint in your code
2. When paused, run in debugger console:
```swift
po RatingService.shared.resetForTesting()
```

**Option C: Add to a debug menu**

If you have a debug/settings screen, add the reset function there.

### Step 2: Test on Real Device

1. **Connect your iPhone/iPad** to your Mac
2. **Select your device** as the build target in Xcode
3. **Build and run** the app on your device

### Step 3: Trigger Rating Prompts

#### Test 2nd Meal Log:
1. Reset rating state (using method from Step 1)
2. Log your **1st meal** - no prompt should appear
3. Log your **2nd meal** - rating dialog should appear ~2 seconds after success animation
4. Check Xcode console for: `DEBUG: [RatingService] Requesting rating dialog - meal log count: 2`

#### Test 5th Meal Log:
1. Reset rating state
2. Log meals 1-4 (no prompts)
3. Log your **5th meal** - rating dialog should appear
4. Check console for: `DEBUG: [RatingService] Requesting rating dialog - meal log count: 5`

#### Test 10th Meal Log:
1. Reset rating state
2. Log meals 1-9 (no prompts)
3. Log your **10th meal** - rating dialog should appear
4. Check console for: `DEBUG: [RatingService] Requesting rating dialog - meal log count: 10`

### Step 4: Test Safeguards

#### Test "Already Rated" Prevention:
1. Reset rating state
2. Log 2 meals to trigger rating
3. When rating dialog appears, rate the app (or dismiss it)
4. Call `RatingService.shared.markAsRated()` (or add this to your code)
5. Log more meals - rating should NOT appear again

#### Test "Max Requests" Prevention:
1. Reset rating state
2. Log 2 meals (1st prompt)
3. Wait at least 1 day (or modify `minDaysBetweenRequests` to 0 for testing)
4. Reset and log 5 meals (2nd prompt)
5. Wait again, reset and log 10 meals (3rd prompt)
6. Reset and log more meals - rating should NOT appear (max 3 reached)

#### Test "Time Between Requests":
1. Reset rating state
2. Log 2 meals (prompt appears)
3. Immediately log 3 more meals (5th total) - prompt should NOT appear (too soon)
4. Wait 1 day (or modify code to allow immediate testing)
5. Log more meals - prompt should appear on 5th

## Debug Logs to Watch For

Watch the Xcode console for these debug messages:

```
DEBUG: [RatingService] Meal log count incremented to: X
DEBUG: [RatingService] Should show rating dialog - meal log count: X, milestone reached
DEBUG: [RatingService] Requesting rating dialog - meal log count: X, request count: Y
DEBUG: [RatingService] Rating dialog requested
```

If conditions aren't met, you'll see:
```
DEBUG: [RatingService] User has already rated, skipping
DEBUG: [RatingService] Maximum rating requests (3) reached, skipping
DEBUG: [RatingService] Too soon since last request (X days), skipping
DEBUG: [RatingService] Conditions not met for rating dialog
```

## Quick Testing Helper

Add this temporary helper function to `RatingService.swift` for easier testing:

```swift
/// Force show rating (for testing only - remove in production)
func forceShowRatingForTesting() {
    print("DEBUG: [RatingService] FORCING rating dialog for testing")
    DispatchQueue.main.async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
```

Then call it from a debug button to test if the dialog appears at all.

## Troubleshooting

### Rating dialog doesn't appear:

1. **Check you're on a real device** - Simulator won't show it
2. **Check console logs** - Are the conditions being met?
3. **Check meal log count** - Call `RatingService.shared.getMealLogCount()` to verify
4. **Apple may suppress it** - Even if code runs, Apple controls when it shows
5. **Try force method** - Use `forceShowRatingForTesting()` to test if dialog works at all

### Rating appears too frequently:

- Check `minDaysBetweenRequests` - increase if needed
- Verify `maxRatingRequests` is set to 3
- Check that `markAsRated()` is being called if user rates

### Rating never appears:

- Verify `incrementMealLogCount()` is being called after successful logs
- Check that `shouldShowRatingDialog()` returns true
- Verify milestones array contains [2, 5, 10]
- Check that you're not hitting max requests limit

## Production Checklist

Before releasing:
- [ ] Remove `resetForTesting()` method OR make it conditional (e.g., only in debug builds)
- [ ] Remove any temporary test buttons
- [ ] Remove `forceShowRatingForTesting()` if added
- [ ] Test on real device to ensure it works
- [ ] Verify rating doesn't appear too frequently
- [ ] Check that rating respects user's choice (if they rate, don't ask again)

## Expected Behavior

✅ **Should appear:**
- On 2nd meal log (if conditions met)
- On 5th meal log (if at least 1 day since last request)
- On 10th meal log (if at least 1 day since last request and < 3 total requests)

❌ **Should NOT appear:**
- On 1st meal log
- On 3rd, 4th, 6th, 7th, 8th, 9th meal logs
- If user already rated
- If 3 requests already made
- If less than 1 day since last request
- In iOS Simulator
