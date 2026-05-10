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
  - Benefits
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
- The gap between the phone and the right-side cards was increased in the latest change.

## Files Most Relevant Right Now

- Main page:
  - `web/app/page.tsx`
- Main styles:
  - `web/app/globals.css`
- Hero image asset:
  - `web/public/hero/voice-meal-logging.png`
- Existing design brief:
  - `design-reference.md`

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
- Build and lint were passing after the latest hero spacing update.
- There is likely still unrelated generated noise in:
  - `web/tsconfig.tsbuildinfo`
- The worktree may be dirty.

## Good Next-Step Prompt For A New Chat

Use something like:

> Read `chat-handoff.md` and then inspect `web/app/page.tsx` and `web/app/globals.css`. Continue improving the LogCal marketing website with a high-fidelity, design-first approach. Do not rebuild the hero from scratch unless necessary. Preserve the current real phone screenshot hero setup and refine from there.

## If The Next Chat Needs To Review Hero Specifically

- Start by checking:
  - desktop spacing between phone and side cards
  - hero vertical alignment
  - card height consistency
  - mobile stacking behavior
- Avoid replacing the real screenshot with a code-built phone mockup.

