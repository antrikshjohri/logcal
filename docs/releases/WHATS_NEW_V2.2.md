# What's New in LogCal v2.2

## What's New (App Store Release Notes)

### Meal Preview Mode
Estimate calories, macros, and line items without logging to your diary. Toggle Preview on the log screen to check foods in advance, with an instant "Log this Meal" button when you're ready to save.

### Non-Blocking Fast Meal Logging
Log meals, photos, or voice notes continuously without waiting for AI estimation to finish. The composer clears immediately and background processing cards stack cleanly with live updates.

### 1-Tap Favourite Logging & Redesigned Sheet
Quickly log any favourite meal with a single tap on the new '+' button. Tapping a favourite meal name opens a newly redesigned, theme-matched bottom sheet with pinned action buttons and customizable serving sizes.

### Dashboard Date Swiping
Swipe left or right anywhere on the Home dashboard to easily navigate between days and view past progress.

### Nutrition Source Citations & Smarter Estimates
Meal breakdowns now cite nutritional references when web-verified, powered by stricter backend macro calculation rules.

### UI Polish & Bug Fixes
Added clear "Edit Description" pill buttons in meal details, fixed layering glitches in meal type dropdowns, and optimized Swift 6 concurrency performance.

---

## Promotional Text (App Store — 170 chars max)

Preview calories without logging, quick log favourites with 1 tap, swipe across dates on the dashboard, and enjoy fast non-blocking logging in LogCal v2.2!

---

## Internal Release Notes

- **Version:** 2.2 (Build 13)
- **Date:** August 2026

### Changes from v2.1 (73e2ff5)

| Area | Change |
|---|---|
| Preview Mode | Added switch toggle to "What did you eat?" header with info banner, accent-blue preview button, and direct "Log this Meal" bypass |
| Queue & Multi-Meal | Added non-blocking pending logging tray with background processing and stacked preview result cards |
| Favourites | Added instant 1-tap `+` log action on favourite meal pills |
| Favourites | Redesigned `SavedMealLogSheet` with app theme background, rounded cards, pinned bottom buttons, and adaptive sheet detents |
| Dashboard | Implemented full-screen horizontal drag gesture on Home dashboard for date switching |
| Meal Details | Replaced plain pencil icon with explicit `[ ✏️ Edit Description ]` / `[ ✕ Close ]` pill button |
| Backend & AI | Integrated OpenAI Responses API with web search capabilities, citation display, and strict macro calculation verification |
| Bug Fixes | Fixed meal type dropdown layering with stable z-indexing, resolved Swift 6 concurrency warnings, and cleaned up resource phases |
