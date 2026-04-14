# Auth And Sync

## Summary

Auth and cloud sync control whether user data stays local only or syncs across devices.

## Entry Points

- `logcal/logcalApp.swift`
- `logcal/ViewModels/AuthViewModel.swift`
- `logcal/Services/CloudSyncService.swift`
- `logcal/Services/FirestoreService.swift`

## Current Auth Behavior

The current app startup flow is built around a fully signed-in user.

Observed behavior in code:

- if there is no current user, the auth view is shown
- if the current user is anonymous, the app signs that user out and shows auth again
- when a real sign-in completes, the main tab UI is shown

Supported sign-in methods in code:

- Google Sign-In
- Sign in with Apple
- anonymous sign-in as a backend fallback path in service-level calls

Important note:
Some older docs in the repo describe auth as optional. That is no longer the best description of the current app behavior.

## Current Sync Behavior

For signed-in users:

- meals are saved locally in SwiftData
- meals are synced to Firestore
- cloud meals can be fetched and merged locally
- daily goal and notification preferences can be synced

For anonymous or signed-out users:

- cloud sync is skipped
- local-only behavior applies

## Data Locations

- local: SwiftData `MealEntry`
- remote: `users/{uid}/meals/*`
- additional write: `mealLogs/*`

## Account Switching

`CloudSyncService` contains logic to:

- clear local meals when switching authenticated accounts
- handle migration from local-only state
- avoid mixing one user's local data with another user's cloud data

## Future Updates

Update this doc when any of these change:

- supported auth providers
- startup auth gating behavior
- cloud sync strategy
- account migration or merge rules
- Firestore data layout for user meal data

