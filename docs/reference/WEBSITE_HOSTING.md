# Website Hosting

This guide covers the LogCal website in `web/` and how it connects to Firebase Hosting.

## Hosting Strategy

The current website is intentionally configured as a static Next.js export for
Firebase Hosting. That is the simplest and most stable setup for the current
marketing site.

If LogCal later needs server-side rendered Next.js behavior, use Firebase App
Hosting for that phase instead of stretching the static Hosting setup beyond its
sweet spot.

## Current Structure

- `web/`: Next.js marketing site and future web app shell
- `web/out/`: generated static output after `npm run build`
- `firebase.json`: root Firebase Hosting config pointing at `web/out`

## Local Commands

```bash
cd web
npm install
npm run dev
npm run build
```

## Deploy Command

From the repository root:

```bash
firebase deploy --only hosting
```

The root `firebase.json` runs `npm --prefix web run build` before deployment.

## Recommended Domain Shape

- `logcalai.com`: marketing site
- `www.logcalai.com`: redirect to the apex domain
- `app.logcalai.com`: future authenticated web app

## Current Website Routes

- `/`: homepage
- `/features/`: feature overview
- `/support/`: support page
- `/privacy/`: privacy summary page
- `/terms/`: terms placeholder page
- `/app/`: future web app placeholder

## Domain Connection Checklist

1. Verify that the Firebase project you want to use for hosting is selected.
2. Build the site locally with `cd web && npm run build`.
3. Deploy with `firebase deploy --only hosting`.
4. In Firebase Hosting, connect `logcalai.com` as the custom domain.
5. Add the DNS records Firebase gives you at your domain registrar.
6. Wait for DNS verification and SSL provisioning to complete.
7. Optionally connect `www.logcalai.com` and redirect it to `logcalai.com`.
8. Reserve `app.logcalai.com` for the future product surface.

## Template Handoff

If you want to adapt an external website template into this codebase, the most
useful formats are:

1. A GitHub repository URL
2. A ZIP or folder added into the workspace
3. Design references showing the homepage, navigation, and mobile layout

Useful notes to include:

- which pages you want to keep
- which parts are only inspiration
- your preferred color/brand direction
- whether the template already includes React or Next.js
