# LogCal Website Handoff

## Project Context

- Repo: `LogCal/logcal`
- Website domain: `logcalai.com`
- Hosting target: Firebase Hosting
- Website lives in `web/` as a Next.js app
- Goal:
  - Stage 1: premium marketing site
  - Stage 2: same web project can later grow into a LogCal web app

## Current State

- A marketing site has already been scaffolded and integrated into this repo.
- The homepage has multiple sections:
  - Hero
  - How it works
  - Features
  - Testimonials
  - Final CTA
  - Footer
- Legal/support routes also exist:
  - `/privacy`
  - `/support`
  - `/terms`
  - `/features`
  - `/app`

## Important Design Direction

- Visual style:
  - premium consumer health app
  - calm, clean, modern
  - Apple-level polish
  - soft off-white / cream background
  - deep green primary color
  - rounded cards
  - subtle shadows
  - lots of whitespace
- User strongly prefers high-fidelity visual matching, not rough approximations.
- For hero/product visuals, real app screenshots are preferred over code-built fake UI when available.

## Hero Section Status

- The hero has been iterated heavily and is the most important visual area.
- Current hero uses a real transparent-background app screenshot, not a CSS mock phone.
- Current hero phone asset:
  - `web/public/hero/voice-meal-logging.png`
- The screenshot was provided by the user and should be treated as the source of truth for the phone visual.
- The right side includes two stacked supporting cards:
  - `Voice log`
  - `Meal recognized`
- Hero spacing was tightened:
  - less whitespace between header and hero
  - less gap between hero and `How it works`
- Header brand text now reads `LogCal AI` with a space.
- Header and homepage `Download the app` buttons now point to the live App Store URL and open in a new tab.

## How It Works Status

- The `How it works` section no longer uses code-built icon/title/body/preview cards.
- It now uses three full-card PNG assets provided by the user:
  - `web/public/how-it-works/speak-it.png`
  - `web/public/how-it-works/snap-it.png`
  - `web/public/how-it-works/track-it.png`
- The numbered circles `1 / 2 / 3` and the dotted connectors between cards were preserved.
- The connector arrow styling was adjusted after the image swap so the arrowhead reads as attached to the dotted line.

## Files Most Relevant Right Now

- Main page:
  - `web/app/page.tsx`
- Main styles:
  - `web/app/globals.css`
- Hero image asset:
  - `web/public/hero/voice-meal-logging.png`
- How it works image assets:
  - `web/public/how-it-works/`
- Features image assets:
  - `web/public/features/`
- Existing design brief:
  - `design-reference.md`

## Features Section Status

- The `Features` section no longer uses code-built cards.
- It now renders six image cards using user-supplied PNG assets:
  - `web/public/features/ai-meal-logging.png`
  - `web/public/features/voice-food-logging.png`
  - `web/public/features/photo-based-estimates.png`
  - `web/public/features/daily-calorie-dashboard.png`
  - `web/public/features/meal-history.png`
  - `web/public/features/streaks-and-consistency.png`
- All six feature assets currently share the same dimensions:
  - `800 x 1127`
- Extra shadow was added to the feature cards so they separate more clearly from the cream background.

## Removed Section

- The old `Benefits` section (`Why LogCalAI makes tracking easier`) was removed from the homepage.
- The page now flows directly from `Features` to `Testimonials`.

## Important History / Lessons

- Earlier attempts tried to recreate the hero phone UI in code.
- That approach caused too much iteration and mismatch.
- The user was unhappy with “approximate” designs and wanted much closer fidelity.
- The best working approach became:
  - use the real app screenshot
  - simplify the hero composition
  - tune spacing/layout around the real asset

## User Preferences

- Prefers direct, visually accurate implementation.
- Does not want generic or scaffold-looking UI.
- Notices spacing/alignment issues quickly.
- Expects strong design judgment and fewer incremental misses.

## Technical Notes

- Commands used successfully:
  - `cd web && npm run lint`
  - `cd web && npm run build`
- Build and lint were passing earlier in the hero iteration phase, but they were not rerun after the newest image-section and copy/link changes in this chat.
- There is likely still unrelated generated noise in:
  - `web/tsconfig.tsbuildinfo`
- The worktree may be dirty.

## Good Next-Step Prompt For A New Chat

Use something like:

> Read `chat-handoff.md` and then inspect `web/app/page.tsx` and `web/app/globals.css`. Continue improving the LogCal marketing website with a high-fidelity, design-first approach. Preserve the real screenshot hero. Keep the `How it works` and `Features` sections image-driven unless the user explicitly wants them rebuilt in code.

## If The Next Chat Needs To Review Hero Specifically

- Start by checking:
  - desktop spacing between phone and side cards
  - hero vertical alignment
  - card height consistency
  - mobile stacking behavior
- Avoid replacing the real screenshot with a code-built phone mockup.

## If The Next Chat Needs To Review Recent Changes

- Check that the App Store CTA links work correctly and open in a new tab.
- Check that the `How it works` image cards still align well on desktop and mobile.
- Check that the `Features` image cards have enough separation/shadow and feel balanced in the grid.
- Remember that the `Benefits` section was intentionally removed and should not be reintroduced unless requested.
