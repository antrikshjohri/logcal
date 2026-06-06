# Changelog

This changelog tracks notable project changes from the point we adopted the new documentation structure.

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
