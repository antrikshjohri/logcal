# What's New in LogCal v1.8

## What's New (App Store Release Notes)

### Try Without Signing In
Start tracking calories immediately with a Guest account — no sign-up required. Upgrade to a full account at any time to back up and sync your data to the cloud without losing your history.

### Custom Macro Goals
Set personalised protein, carbs, and fat targets alongside your daily calorie goal. Not sure what to aim for? Use the new "Help Me Choose" guided questionnaire to get a recommended macro split based on your diet style.

### Log Meals via WhatsApp
You can now log meals directly from WhatsApp — no app required. Just send a message and LogCal handles the rest. Set it up under Shortcuts in your Profile.

### Favourites Sync to Cloud
Your saved favourite meals are now backed up to the cloud and sync across devices automatically. Reorder them on the Log screen to match your logging habits.

### Send Feedback
Share thoughts directly from the app. Tap "Send Feedback" in your Profile or use the quick link at the bottom of the Log screen — we read every message.

### Smarter History
Meals logged for future dates now correctly appear above today in your History — exactly where you'd expect them.

### Keyboard-Friendly Logging
The "Log Meal" button now stays visible above the keyboard when you're typing, so you never lose track of how to submit.

### Bug Fixes & Polish
Offline mode now shows a clear message when there's no internet connection. Various stability and performance improvements across the app.

---

## Promotional Text (App Store — 170 chars max)

Track calories effortlessly with AI. Log by text, voice, or WhatsApp. Custom macros, guest mode, favourites sync, and smarter history — all in v1.8.

---

## Internal Release Notes

- **Version:** 1.8 (Build 9)
- **Date:** June 2026

### Changes from v1.7

| Area | Change |
|---|---|
| Guest Account | Full anonymous auth + upgrade-to-full-account flow with `LinkAccountView` |
| Guest Account | Sign-in prompts on Log and History screens for guest users |
| Custom Macros | New `DailyGoalView` with per-macro steppers (protein, carbs, fat) |
| Custom Macros | New `DietStyleHelperView` questionnaire ("Help Me Choose") with `DietStyle` model |
| Custom Macros | Macro goals persisted and synced to Firestore via `FirestoreService` |
| WhatsApp | Full interactive WhatsApp messaging flow without business verification |
| WhatsApp | "Help Me Choose" and account management commands via WhatsApp |
| Favourites | Cloud sync for `SavedMeal` to Firestore — survives reinstalls |
| Favourites | Drag-to-reorder favourites on Log screen with `displayOrder` persistence |
| Feedback | New `FeedbackSheet` with Firestore write + Firestore security rules |
| Feedback | Entry points in Profile ("Send Feedback") and Log screen (bottom link) |
| Profile | Renamed "WhatsApp Integration" section to "Shortcuts" |
| History | Fixed sort order — future dates appear above today |
| Log Screen | Log Meal button floats above keyboard when input is focused |
| Log Screen | Keyboard dismiss via scroll (`.scrollDismissesKeyboard(.interactively)`) |
| Network | Offline/disconnected state shows user-facing error message |
| Analytics | 100% tap-event coverage on WhatsApp, Daily Goal, Diet Style Helper, and Profile screens |
| Analytics | 30+ new Firebase Analytics events |
| Crashlytics | Added Firebase Crashlytics for crash reporting |
| Labels | Renamed "kcal" → "cal" throughout the app |
