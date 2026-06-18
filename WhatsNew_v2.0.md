# What's New in LogCal v2.0 🚀

Welcome to LogCal Version 2.0! This release brings highly requested tracking metrics, visual improvements, and complete data safety across all platforms (iOS, Android, and WhatsApp chatbot).

---

## 🌿 1. Fiber Tracking Integration
You can now track dietary fiber alongside Protein, Carbohydrates, and Fats.
- **Derived Daily targets**: Your daily fiber goal is dynamically calculated client-side as **14g of fiber per 1,000 calories** of your daily goal (matching USDA standard guidelines).
- **Goal Guidelines info**: Tap the new **info ("i") icon** on the Daily Targets screen to view the formula explanation.
- **Dashboard Progress**: A dedicated Warm Olive progress row has been added to the dashboard macros card to display your today's fiber intake progress.
- **Multi-Platform Sync**: Supported across iOS, Android, and WhatsApp confirmation templates and progress messages.
- **Optimized UI Layout**: Macro pills in log success states and editors have been reduced in size and configured with wrap behavior to fit neatly in a single row without clutter.

---

## 🗑️ 2. Multi-Platform Soft-Delete (Data Safety)
Never lose your logs accidentally. Deleting a meal log now flags it as soft-deleted across all sync points:
- **Offline Parity**: Support added for Room (Android) and SwiftData (iOS) local databases.
- **Firestore Synchronization**: Real-time sync engines now automatically distribute soft-delete status without losing raw entries, preventing sync gaps.
- **WhatsApp Webhook Alignment**: The daily summaries calculated by the WhatsApp chatbot automatically ignore soft-deleted logs.

---

## 🎨 3. Android Visual & Usability Optimizations
- **Polished Bottom Navigation**: Restructured the Custom Floating Bottom Navigation bar safe-area padding using `navigationBarsPadding()` so gesture navigation doesn't overlap labels. Balanced heights make active indicators perfectly equidistant.
- **Refinement Inputs State**: When refining meals, the description input now transitions to a disabled loading state matching the iOS interface.

---

### Verification
All compiled code and assets have been verified, compiled, and tested locally. We are ready for release!
