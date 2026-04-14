# Documentation Workflow

This file defines how we keep LogCal documented going forward.

## Principle

Documentation is part of the feature, fix, or refactor.
A task is not fully done until the relevant docs are updated.

## Canonical Docs to Maintain

These docs should stay current:

- `docs/README.md`
- `docs/SETUP.md`
- `docs/ARCHITECTURE.md`
- `docs/CHANGELOG.md`
- files in `docs/FEATURES/`

App Store release notes live separately in:

- `docs/releases/`

Operational reference docs live in:

- `docs/reference/`

Historical docs live in:

- `docs/legacy/`

## Definition of Done

For every meaningful change, update at least one of the following:

- `CHANGELOG.md` for visible behavior changes
- a feature doc if product behavior changed
- `ARCHITECTURE.md` if responsibilities or data flow changed
- `SETUP.md` if local setup or deployment changed

For release prep, also add or update a file in `docs/releases/`.

## When to Create a Feature Doc

Create or expand a feature doc when:

- a user-facing feature is added
- an existing flow changes materially
- a feature spans iOS and Firebase backend work
- the implementation has important caveats or constraints

## When to Create a Decision Doc

Use a decision note when:

- there are multiple valid approaches
- we make a tradeoff we may revisit later
- future contributors would otherwise repeat the same debate

Decision docs should be short and practical.

## Changelog vs Release Notes

Use:

- `docs/CHANGELOG.md` for internal engineering history
- `docs/releases/WHATS_NEW_Vx.y.md` for App Store-facing release notes

The changelog can be technical and cumulative.
Release notes should be concise and user-facing.

## Reference vs Legacy

Use:

- `docs/reference/` for still-useful setup, submission, analytics, or troubleshooting material
- `docs/legacy/` for superseded or historical notes that are no longer current

If a document is still useful for real work today, it belongs in `reference`.
If it mainly explains an older project phase, it belongs in `legacy`.

## Suggested Workflow for Future Tasks

1. Define the task
2. Identify affected areas in code
3. Identify which docs must change
4. Make the code change
5. Update docs in the same pass
6. Note any remaining gaps explicitly

## Prompting Rule for Codex

To keep docs current, prefer prompts like:

- "Implement X and update all relevant docs."
- "Before coding, update the feature doc for X."
- "Make this change and update architecture, setup, and changelog if needed."

## Style Guide

- Prefer short, current, practical docs over aspirational docs
- Separate current truth from legacy notes
- When a doc is historical, say so clearly
- Link to code paths when useful
- Do not leave conflicting instructions in canonical docs

## Legacy Docs

Older docs may remain in the repository for reference.
When they conflict with the current implementation:

- update the canonical docs
- move or keep the doc under `reference` or `legacy` as appropriate
- add a note to the older doc if it is still likely to be opened
- avoid silently relying on outdated instructions
