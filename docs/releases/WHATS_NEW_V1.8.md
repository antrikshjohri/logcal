# What's New in LogCal v1.8

## What's New (App Store Release Notes)

### Send Feedback
You can now share feedback directly from within the app. Tap "Send Feedback" in your Profile or use the quick link at the bottom of the Log screen — we read every message.

### WhatsApp Logging Improvements
Log meals by chatting naturally on WhatsApp. Setup is faster, the connection status is clearer, and the entry point is now found under the new "Shortcuts" section in Profile.

### Smarter History
Meals logged for future dates now correctly appear above today in your History — exactly where you'd expect them.

### Keyboard-Friendly Logging
The "Log Meal" button now stays visible above the keyboard when you're typing, so you never lose track of how to submit your meal.

### Bug Fixes & Polish
Offline mode now shows a clear message when there's no internet connection. Various stability and performance improvements across the app.

---

## Promotional Text (App Store — 170 chars max)

Track calories effortlessly with AI. Log meals by text, voice, or photo. Now with in-app feedback, smarter history, and a keyboard-friendly logging experience.

---

## Internal Release Notes

- **Version:** 1.8 (Build 9)
- **Branch merged:** feat/feedback → main
- **Date:** June 2026

### Changes from v1.7

| Area | Change |
|---|---|
| Feedback | New `FeedbackSheet` with Firestore write + Firestore security rules |
| Feedback | Entry points in Profile ("Send Feedback") and Log screen (bottom link) |
| WhatsApp | Renamed "WhatsApp Integration" section to "Shortcuts" in Profile |
| History | Fixed sort order — future dates now appear above today |
| Log Screen | Log Meal button floats above keyboard when input is focused |
| Log Screen | Keyboard dismiss via swipe-scroll (`.scrollDismissesKeyboard(.interactively)`) |
| Network | Offline/disconnected state now shows a user-facing error message |
| Analytics | 100% tap-event coverage on WhatsApp, Daily Goal, Diet Style Helper, and Profile screens |
| Analytics | New events: `profile_*`, `whatsapp_*`, `daily_goal_*`, `diet_style_helper_*`, `feedback_submitted` |
