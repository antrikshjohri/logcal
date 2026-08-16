# Changelog

This changelog tracks notable project changes from the point we adopted the new documentation structure.

## 2026-08-17 (v2.2)

- Prepared App Store release notes for v2.2 and bumped iOS app marketing version to `2.2` (build `13`)
- Added Meal Preview Mode to estimate calories, macros, and line items without logging to diary, with direct 1-tap "Log this Meal" action
- Implemented non-blocking background meal logging queue with immediate composer reset and stacked multi-meal preview cards
- Added direct 1-tap `+` quick-log shortcut to Favourite meal pills on the Log screen
- Redesigned Favourite meal details bottom sheet (`SavedMealLogSheet`) with app theme styling, rounded cards, pinned action buttons, and adaptive sheet detents
- Added full-screen horizontal swipe gesture across the Home Dashboard to easily navigate between dates
- Replaced ambiguous meal edit icon with an explicit `[ ✏️ Edit Description ]` / `[ ✕ Close ]` pill button
- Added nutrition source citation badges and verified calculation rules across backend AI estimation pipelines
- Fixed meal type dropdown layering glitches with stable z-indexing
- Swift 6 concurrency cleanup and compiler warning resolutions

## 2026-06-22 (v2.1)

- Prepared App Store release notes for v2.1 and bumped the iOS app marketing version to `2.1` (build `12`)
- Added Lock Screen and Home Screen widgets to view daily calorie progress and log meals via shortcuts
- Enabled viewing local photos of logged meals directly inside the history log with full-screen zoom overlays
- General performance improvements, visual polishing, and bug fixes (including widget layout optimization and keyboard issues)

## 2026-06-15 (v2.0)

- Bumped the iOS app marketing version to `2.0` (build `11`)
- Added dietary fiber tracking to daily goals, calculated as 14g per 1,000 calories
- Info ("i") popup added to the Daily Goals screens explaining standard USDA guideline formulas
- warmOlive macro progress row added to the macro breakdown card for visual fiber progress tracking
- Reduced font size and enabled horizontal auto-wrap for macro badge pills in log states and lists
- Integrated soft-delete flag (`isDeleted`) across local storage (SwiftData, Room) and remote database (Firestore)
- WhatsApp webhook daily summaries updated to automatically exclude soft-deleted meals
- Restructured Custom Floating Bottom Navigation bar padding using `navigationBarsPadding()` on Android
- Description input disabled and shows inline loading indicator during AI generation transitions

## 2026-06-10 (v1.9)

- Bumped the iOS app marketing version to `1.9` (build `10`)
- Smooth auto-scroll back to top after pull-to-refresh completes using `ScrollViewReader` on History View
- Prevent full-screen blocking overlay if `activeMeals` is already loaded (sync loader shows only when empty)
- Milestones updated to `[1, 3, 5]` logged meals for rating prompt triggers
- Replicated rating prompts on Android in preparation for launch
- Robust fallback decoding for both `snake_case` and `camelCase` response keys in `MealLogResponse`
- Made confidence field optional in `MealItem` to handle backend response updates safely

## 2026-04-15

- Added canonical documentation for the current iOS app and Firebase backend
- Added a documentation workflow to make doc updates part of the definition of done
- Added feature docs for meal logging and auth/cloud sync
- Marked older setup and feature docs as legacy references where appropriate
- Reorganized docs into canonical, reference, legacy, and release-note sections
- Updated the iOS dictation composer so recording now exposes `Stop` and inline send actions, and `Log Meal` can submit directly while recording
- Added a `Cancel` action to the iOS recording strip to discard an in-progress voice recording without transcription
- Switched the backend dictation transcription model from `whisper-1` to `gpt-4o-mini-transcribe` for testing

## 2026-05-04

- Prepared the App Store release notes for v1.6
- Bumped the iOS app marketing version to `1.6`
- Bumped the iOS build number to `7`

## 2026-05-10

- Added a new `web/` Next.js codebase for the LogCal marketing website and future web app shell
- Added website routes for home, features, support, privacy, and a future `/app` surface
- Preserved the existing full privacy policy and legacy support page inside the new website public assets
- Added Firebase Hosting configuration to deploy the static website from `web/out`
- Updated the canonical docs to cover the new web architecture and setup flow
- Rebuilt the website homepage around a premium consumer-app landing page direction
- Added a reusable App Store placeholder link, richer product mockups, and a placeholder `Terms` route
- Recreated the website homepage from the seven section-level design references: hero, how it works, features, benefits, testimonials, final CTA, and footer

## 2026-05-11

- Added a reusable LogCal AI SEO blog agent spec for product-led blog articles
- Added a copy-ready SEO blog article prompt template for future content generation
- Added the first LogCal AI SEO blog draft about tracking calories without weighing food
- Added a website Blog section with a blog index, article route, placeholder visuals, and SEO schema
- Updated the SEO blog agent with production article rules, region-agnostic defaults, portion guidance, and image-generation prompt requirements

## 2026-05-29 (v1.7)

- Prepared App Store release notes for v1.7 and bumped the iOS app marketing version to `1.7` (build `8`)
- Added native universal support for iPad (updated targeted device family configuration to `"1,2"`)
- Implemented responsive navigation selection routing with `AppRootView` using `NavigationSplitView` on iPad and `TabView` on iPhone
- Optimized the iPad dashboard layout to display in two side-by-side columns (calories and macros on the left; weekly trends, daily goal, and streak cards on the right)
- Integrated an iPad-exclusive "Today's Meals" list section at the bottom of the home dashboard
- Added dynamic text scaling (`minimumScaleFactor`) on small widget cards to prevent label truncation under narrow iPhone portrait modes and iPad multitasking Split Views
- Constrained and centered settings, profile sheets, and detail views to `650pt` max-width on iPad screens
- Implemented a complete `SavedMeal` favorite meals model and list interface, including quick-log actions from the Log composer
- Revamped the app-wide font system to use SF Pro Rounded typography
- Re-architected meal details view to support custom capsule macro pills and specific meal type icons (sunrise, sun, stars)
- Defaulted the History view to expand the two most recent logging days automatically for better quality of life
- Improved meal logging speed by approximately 50% through service optimization

## 2026-06-07 (v1.8)

- Bumped iOS app marketing version to `1.8` (build `9`)
- Added in-app feedback feature (`FeedbackSheet`) with Firestore persistence and updated security rules
- Added feedback entry points in Profile screen ("Send Feedback" row) and Log screen (bottom link)
- Renamed "WhatsApp Integration" section header in ProfileView to "Shortcuts"
- Fixed History sort order so future-dated meals appear above today instead of below
- Log Meal button now floats above the keyboard when the text input is focused; returns inline when keyboard is dismissed
- Added `.scrollDismissesKeyboard(.interactively)` for natural swipe-to-dismiss on the Log screen
- Added offline/network disconnected user-facing error message
- Implemented 100% tap-event analytics coverage for ProfileView, LinkWhatsAppView, DailyGoalView, and DietStyleHelperView
- Added 30+ new Firebase Analytics events across the above screens
