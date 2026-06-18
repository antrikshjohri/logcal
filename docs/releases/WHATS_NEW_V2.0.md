# What's New in LogCal v2.0

## What's New (App Store Release Notes)

### Fiber Tracking
Track dietary fiber alongside protein, carbs, and fats. Your daily fiber goal is dynamically calculated based on your calorie target (14g per 1,000 calories) with a helpful info popup explaining the calculation.

### Dashboard & UI Polish
See your daily fiber progress clearly in Warm Olive. We've also optimized the layout of macro pills to wrap beautifully and stay readable, even on smaller screens.

### Multi-Platform Soft-Delete
Delete meals with confidence. Logs are now soft-deleted across SwiftData, Android's Room DB, and Firestore, ensuring absolute sync parity and data safety.

### Usability Improvements
Android features a polished custom bottom navigation bar that sits perfectly above system gestures, plus loading states when refining logs.

---

## Promotional Text (App Store — 170 chars max)

Track dietary fiber with dynamic targets, enjoy seamless multi-platform soft-delete, and experience polished layout improvements in LogCal v2.0!

---

## Internal Release Notes

- **Version:** 2.0 (Build 11)
- **Date:** June 2026

### Changes from v1.9

| Area | Change |
|---|---|
| Fiber Tracking | Added dietary fiber tracking to daily goals, calculated as 14g per 1,000 calories |
| Fiber Tracking | Info ("i") popup added to the Daily Goals screens explaining standard USDA guideline formulas |
| Dashboard / UI | warmOlive macro progress row added to the macro breakdown card for visual fiber progress tracking |
| Log Editor / Pills | Reduced font size and enabled horizontal auto-wrap for macro badge pills in log states and lists |
| Sync / Data | Integrated soft-delete flag (`isDeleted`) across local storage (SwiftData, Room) and remote database (Firestore) |
| Sync / Data | WhatsApp webhook daily summaries updated to automatically exclude soft-deleted meals |
| Navigation (Android) | Restructured Custom Floating Bottom Navigation bar padding using `navigationBarsPadding()` |
| Meal Refinement | Description input disabled and shows inline loading indicator during AI generation transitions |
