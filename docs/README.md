# LogCal Documentation

This folder contains the canonical documentation for the iOS app and Firebase backend.

## Start Here

If you are new to the project, read these in order:

1. [SETUP.md](./SETUP.md)
2. [ARCHITECTURE.md](./ARCHITECTURE.md)
3. [DOCUMENTATION_WORKFLOW.md](./DOCUMENTATION_WORKFLOW.md)

## Canonical Docs

These files should reflect the current state of the codebase.

- [SETUP.md](./SETUP.md): local setup for the iOS app and Firebase Functions
- [ARCHITECTURE.md](./ARCHITECTURE.md): app structure, data flow, and backend responsibilities
- [CHANGELOG.md](./CHANGELOG.md): notable project changes going forward
- [DOCUMENTATION_WORKFLOW.md](./DOCUMENTATION_WORKFLOW.md): rules for keeping docs current

## Release Notes

App Store-facing release notes live in [`releases/`](./releases).

- [releases/README.md](./releases/README.md)

## PRDs

Product requirement docs and feature planning docs live in [`PRDS/`](./PRDS).

## Reference Docs

Operational and task-specific docs live in [`reference/`](./reference).

- [reference/README.md](./reference/README.md)

## Legacy Docs

Historical docs that may not match the latest code live in [`legacy/`](./legacy).

- [legacy/README.md](./legacy/README.md)

## Feature Docs

Feature-level docs live in [`FEATURES/`](./FEATURES).

- [meal-logging.md](./FEATURES/meal-logging.md)
- [auth-and-sync.md](./FEATURES/auth-and-sync.md)

## Templates

Reusable templates live in [`TEMPLATES/`](./TEMPLATES).

- [feature-template.md](./TEMPLATES/feature-template.md)
- [decision-template.md](./TEMPLATES/decision-template.md)

## Documentation Rule

From this point forward, every meaningful code change should update at least one of:

- `CHANGELOG.md`
- a file in `FEATURES/`
- `ARCHITECTURE.md`
- `SETUP.md`

For App Store submissions, create or update a release note in `docs/releases/`.

For focused operational tasks, add or update a doc in `docs/reference/`.

If a doc is historical or superseded, move it into `docs/legacy/`.
