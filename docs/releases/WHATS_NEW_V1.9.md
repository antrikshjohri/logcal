# What's New in LogCal v1.9

## What's New (App Store Release Notes)

### Smooth History Refresh
Refreshing your history is now smoother. After a pull-to-refresh completes, the view smoothly scrolls back to the top automatically.

### Non-Intrusive Syncing
The full-screen syncing overlay now only displays if you have no meals loaded, ensuring background refreshes never block you from viewing your logged meals.

### Smarter Rating Prompts
We've updated when we ask for your feedback. Rating prompts now appear at natural breakpoints after your 1st, 3rd, and 5th logged meals, keeping prompts friendly and rare.

### Under the Hood
Added robust cross-platform parsing support for backend response fields to keep meal analysis running reliably, plus minor bug fixes.

---

## Promotional Text (App Store — 170 chars max)

Enjoy smoother history pull-to-refresh, smarter rating prompts, and non-intrusive background syncing in LogCal v1.9.

---

## Internal Release Notes

- **Version:** 1.9 (Build 10)
- **Date:** June 2026

### Changes from v1.8

| Area | Change |
|---|---|
| History View | Smooth auto-scroll back to top after pull-to-refresh completes using `ScrollViewReader` |
| History View | Prevent full-screen blocking overlay if `activeMeals` is already loaded (sync loader shows only when empty) |
| Rating Prompts | Milestones updated to `[1, 3, 5]` logged meals for prompt triggers |
| Rating Prompts | Replicated exactly on Android in preparation for launch |
| API / Model | Robust fallback decoding for both `snake_case` and `camelCase` response keys in `MealLogResponse` |
| API / Model | Made confidence field optional in `MealItem` to handle backend response updates safely |
