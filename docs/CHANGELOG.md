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
