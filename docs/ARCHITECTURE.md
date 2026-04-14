# Architecture

This document describes the current architecture of the LogCal iOS app and Firebase backend.

## High-Level Overview

LogCal is an iOS calorie logging app with an AI-assisted meal analysis backend.

Primary stack:

- SwiftUI for the app UI
- SwiftData for local meal persistence
- Firebase Auth for identity
- Firebase Functions for secure OpenAI calls
- Firestore for cloud sync and remote config

## Main User Flows

### Meal Logging

1. User enters meal text, voice dictation, a meal photo, or a combination.
2. `LogViewModel` prepares the request.
3. `OpenAIService` routes the request.
4. In production mode, `FirebaseService` calls the Firebase callable function.
5. Firebase Functions call OpenAI and return structured meal data.
6. The app stores the meal locally in SwiftData as `MealEntry`.
7. If the user is signed in, `CloudSyncService` writes the meal to Firestore.

### Auth and Session

1. `logcalApp` initializes Firebase on launch.
2. `AuthViewModel` observes Firebase auth state.
3. The app shows the auth flow when there is no fully signed-in user.
4. Cloud sync and profile behavior depend on the auth state.

### History and Dashboard

- `DashboardView` computes totals from local SwiftData meals
- `HistoryView` groups meals by day and supports refresh/delete flows
- Firestore sync merges remote meals into local storage

## iOS App Structure

### App Entry

- `logcal/logcalApp.swift`

Responsibilities:

- initialize Firebase
- configure analytics and notifications
- own top-level environment objects
- gate the app behind auth state
- host the four main tabs

### Core Views

- `Views/DashboardView.swift`
- `Views/HomeView.swift`
- `Views/HistoryView.swift`
- `Views/ProfileView.swift`
- `Views/AuthView.swift`

### Core View Models

- `ViewModels/LogViewModel.swift`
- `ViewModels/AuthViewModel.swift`

### Core Services

- `Services/OpenAIService.swift`: chooses direct OpenAI vs Firebase-backed path
- `Services/FirebaseService.swift`: Firebase callable interface for meal logging and transcription
- `Services/FirestoreService.swift`: Firestore persistence for meals, goals, and preferences
- `Services/CloudSyncService.swift`: merges local and remote meal data
- `Services/AppConfigService.swift`: reads remote minimum-version config from Firestore
- `Services/NotificationService.swift`: schedules smart meal reminders
- `Services/AnalyticsService.swift`: event tracking
- `Services/SpeechRecognitionService.swift`: dictation flow

## Local Data Model

### `MealEntry`

`MealEntry` is the main persisted model in SwiftData.

Important fields:

- `id`
- `timestamp`
- `createdAt`
- `foodText`
- `mealType`
- `totalCalories`
- `rawResponseJson`
- `hasImage`

`rawResponseJson` stores the structured AI response so the app can derive macro totals and meal item detail later.

## Backend Architecture

### Firebase Functions

Main backend file:

- `functions/src/index.ts`

Current responsibilities include:

- `logMeal`
- `refineMealLog`
- `transcribeAudio`
- OpenAI request construction
- rate limiting via Firestore
- secure use of the OpenAI API key via Firebase secret

### Firestore

Firestore is currently used for:

- `users/{uid}/meals/*`
- user-level settings such as daily goal and notification preferences
- app config document(s)
- usage tracking for backend limits
- an additional `mealLogs` collection for combined meal visibility

## Configuration

### App-side

Key config lives in:

- `logcal/Utils/Constants.swift`

Notable behavior:

- `Constants.API.useFirebase` is currently `true`
- dictation language can be influenced by user defaults
- meal type inference includes IST-based defaults

### Backend-side

Key config lives in:

- `functions/src/index.ts`
- Firebase project settings
- Firebase secret `OPENAI_API_KEY`

## Documentation Notes

Older docs in this repo were written during multiple product iterations.
Some of them describe earlier auth assumptions or setup flows.
Use this file as the current architectural reference and update it whenever the system shape changes.

