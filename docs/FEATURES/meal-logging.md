# Meal Logging

## Summary

Meal logging is the core product flow.
Users can log a meal with text, speech input, a photo, or a combination of text and photo.

## Entry Points

- `logcal/Views/HomeView.swift`
- `logcal/ViewModels/LogViewModel.swift`
- `logcal/Services/OpenAIService.swift`
- `logcal/Services/FirebaseService.swift`
- `functions/src/index.ts`

## Current Behavior

- user selects a date
- user selects or accepts an inferred meal type
- user can enter freeform meal text
- user can attach a meal image
- user can use speech dictation
- app submits the meal for AI analysis
- app saves the result locally
- signed-in users sync the saved meal to Firestore

### Dictation Behavior

- tapping the mic starts recording
- while recording:
  - camera and photo actions are hidden so the composer focuses on voice actions
  - a live waveform reacts to the user's voice while recording
  - `Cancel` discards the active recording without transcription
  - `Stop` ends recording and transcribes into the text box only
  - the inline send control ends recording, transcribes, and logs immediately
  - `Log Meal` behaves the same as send while recording
- while transcription is running, submission waits until transcription completes
- transcribed text is appended to any existing meal text

## Backend Path

Current default path:

1. iOS app uses `OpenAIService`
2. `OpenAIService` routes to `FirebaseService`
3. Firebase callable function sends the request to OpenAI
4. structured meal data is returned to the app

The app is currently configured to use Firebase by default.

## Data Saved

Each saved meal stores:

- visible meal text
- meal type
- timestamp
- total calories
- raw structured response JSON
- whether an image was used

The raw JSON is used to reconstruct item-level macros later.

## Related UX

- confetti/success feedback after a successful log
- quick preview of the logged meal
- quick refine/edit support for correcting the estimate
- notification rescheduling after logging

## Constraints

- no Android behavior is documented here yet
- production flow depends on Firebase Functions and OpenAI secret setup
- app version gating can block logging if a minimum required version is configured remotely

## Future Updates

Update this doc when any of these change:

- request shape to backend
- logging input types
- save/sync behavior
- refine/correction flow
- meal result schema
