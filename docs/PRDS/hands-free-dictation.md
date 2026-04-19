# PRD: Hands-Free Dictation For Meal Logging

## Status

Draft

## Date

2026-04-15

## Owner

LogCal iOS

## Summary

Improve the dictation flow to feel more like ChatGPT voice input:

1. User taps mic to start dictation
2. User speaks
3. While recording, the UI offers two outcomes:
   - `Stop`: stop recording and transcribe into the text box only
   - `Send` or `Log Meal`: stop recording, transcribe, and submit immediately
4. The user can choose either review-first or send-now without an extra stop tap in the fast path

This keeps the user in control while making the common dictation flow faster.

## Problem

The current dictation flow works, but it does not feel intentional.
The same mic control both starts and stops recording, and the relationship between dictation and meal submission is not especially clear.

We want a clearer voice mode with:

- an explicit recording state
- an explicit review-first action
- an explicit send-now action while recording

This is closer to the mental model users already know from ChatGPT voice input.

## Current Implementation

Relevant code:

- `logcal/Views/HomeView.swift`
- `logcal/ViewModels/LogViewModel.swift`
- `logcal/Services/SpeechRecognitionService.swift`
- `logcal/Services/FirebaseService.swift`

Current behavior:

- tapping the mic toggles recording on/off
- while recording, `SpeechRecognitionService` writes audio to a local `.m4a` file
- when recording stops, the app sends the full clip to Firebase callable `transcribeAudio`
- transcription result is merged into `foodText`
- `logMeal()` already safely waits for dictation/transcription to finish before submitting

Important technical constraint:

- this is not live streaming transcription today
- the current architecture is "record first, transcribe after stop"

## Product Goal

Make dictation feel deliberate, modern, and easy to understand without removing user control over the final meal log.

## Non-Goals

- fully streaming live transcription
- automatic meal submission with no user review
- redesigning the entire logging screen
- Android changes

## User Stories

- As a user, I want to tap once, speak naturally, and then choose whether to review or send.
- As a user, I want clear visual feedback that the app is listening, then processing.
- As a user, I want a safe path to transcribe without submitting.
- As a user, I want a fast path to submit immediately when I know my dictation is done.

## UX Principles

- one tap to start
- explicit stop action while recording
- explicit send action while recording
- preserve normal `Log Meal` semantics
- obvious state transitions
- preserve trust by keeping review before submit

## Chosen Experience

We are explicitly not doing silence-based auto-stop in this phase.

Chosen model:

- `Start dictation` is one action
- `Stop` is a visible review-first action while recording
- `Send` is a visible submit-now action while recording
- `Log Meal` stays active while recording and behaves the same as `Send`

This mirrors the ChatGPT pattern more closely and avoids hidden system behavior.

## Proposed UX

### Idle state

- mic button is visible in the composer area
- `Log Meal` button behaves normally

### Recording state

- the composer enters a clear voice-recording mode
- the primary recording control changes from mic to `Send`
- a separate `Stop` control is visible
- no helper text is shown
- `Log Meal` remains active and behaves the same as `Send`

### Transcribing state

- recording has ended
- UI shows `Transcribing...`
- stop/send controls are no longer shown
- dictation controls are temporarily disabled
- `Log Meal` remains disabled until transcription completes

### Transcript ready

- transcribed text is inserted into the meal text box
- user can review or edit it
- `Log Meal` becomes active again
- user taps `Log Meal` to submit

## UI Pattern Options

### Option A: Keep the current icon row and swap mic -> send

Recording state:

- current mic button becomes a send-style icon button
- a separate stop icon button appears next to it
- `Log Meal` stays active below

Pros:

- minimal layout change
- easiest to implement
- works with the current composer
- closest to the visual simplicity of ChatGPT voice input

### Option B: Add a compact voice action strip above the main CTA

Recording state:

- composer shows a dedicated strip with `Stop` and `Send`
- main `Log Meal` button remains visible below and stays active

Pros:

- clearest semantics
- strong separation between voice controls and normal CTA

Risks:

- slightly more layout work

### Option C: Full voice mode composer

Recording state:

- input area visually shifts into a dedicated voice mode
- `Stop`, `Send`, and status copy are more prominent

Pros:

- strongest, most intentional voice UX

Risks:

- biggest design and implementation lift

## Recommended UI Variant

Recommend Option A for the first release.

Reason:

- it preserves the current screen structure
- it introduces the new behavior with the smallest UI delta
- it is fast to ship and easy to tune
- we can later evolve it toward Option B or C if needed
- it matches the desired icon-first, low-copy interaction style

## Functional Requirements

- one tap starts dictation
- while recording, user must have a visible `Stop` action
- while recording, user must have a visible `Send` action
- while recording, tapping `Log Meal` must behave the same as tapping `Send`
- app must not submit the meal automatically
- `Send` and `Log Meal` while recording must:
  - stop recording
  - wait for transcription
  - continue into the normal log flow automatically
- `Stop` while recording must:
  - stop recording
  - wait for transcription
  - leave the transcript in the text box without submitting
- app must keep existing protections that wait for transcription before `logMeal()`
- app must continue showing error states for:
  - mic permission denied
  - recording too short
  - no speech detected
  - transcription/network failure

## Edge Cases

- user starts recording and says nothing
- user taps Log Meal while transcription is still running
- user wants to cancel dictation completely
- user repeatedly starts and stops short recordings
- user has existing typed text and then appends dictation to it
- user taps `Send` or `Log Meal` while there is also an attached image
- user taps `Stop`, edits the transcript, then logs normally

## Telemetry

If implemented, consider tracking:

- dictation_manually_stopped
- dictation_sent_from_voice_control
- dictation_sent_from_log_meal
- dictation_timeout_or_too_short
- dictation_transcription_failed
- dictation_transcription_completed

## Open Questions

- Stop control should be icon-only
- Send control should be icon-first and visually consistent with the current composer controls
- Should we add a separate `Cancel` action later, or only `Stop` in v1?
- Do we want a subtle waveform/level meter, or is the current animated listening state enough?
- Should the recording state visually expand into a larger voice composer, or stay compact in the current input area?

## Decision For Brainstorm

Current proposed decision:

- do not use silence-based auto-stop
- keep review-first available via `Stop`
- while recording, use:
  - `Stop` = transcribe only
  - `Send` = transcribe and submit
  - `Log Meal` = same as `Send`
- keep the recording experience explicit and button-driven
- use icon-based controls with no helper text, similar to ChatGPT's voice input minimalism
