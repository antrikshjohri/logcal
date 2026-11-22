# Private WhatsApp agent pilot

## Scope and implementation plan

1. Preserve the actual deployed source, verify its hash against Git, and tag it.
2. Add a private allowlisted route with a global flag and per-user `/legacy` override.
3. Queue agent requests durably and process them in arrival order with bounded retries.
4. Implement read tools for nutrition data, an estimate-only tool, and an explicit meal-record tool; use one conversational model for Q&A and coaching.
5. Test legacy equivalence, account isolation, calculations, write intent, retries, and rollback; deploy only WhatsApp functions and enable the verified owner's account.

The pilot supports text, voice, and photos; meal logging plus logged-data questions,
nutrition coaching, and general workout advice. It does not save workouts, change
goals, or access device health data. Existing meal schemas, callable app APIs,
mobile sources, and Firestore rules are unchanged. Meal edit/delete/date buttons
continue through the existing handler. Coaching advice is not saved as a meal.

## Verified production baseline

Tag: `whatsapp-prod-before-agent-2026-11-22`, commit `2eede6a`.
The release manifest records the deployed function time and source/package hashes.
All deployed TypeScript files and package/lock/config files matched this commit.
The original deployed source archive is retained in `deployments/whatsapp/`, with
its SHA-256 recorded in the manifest. It contains Firebase runtime configuration
but no secret values; secret references remain managed in Google Secret Manager.

Development branch: `codex/whatsapp-agent`. The original main branch stays intact.

## Controls

Run from the repository root using a Firebase CLI login authorized for logcal-ai:

```sh
node functions/scripts/whatsapp-agent.cjs status
node functions/scripts/whatsapp-agent.cjs disable
node functions/scripts/whatsapp-agent.cjs enable
```

The backend-only `app/whatsappAgent` document defaults to disabled when absent.
Both a true enabled flag and the verified pilot UID in allowedUids are required.
The implementation also hard-limits this release to that UID, so accidentally
adding another account to the flag does not enroll it. Other users take the
existing route without reading new config or conversation state. The operator
verified this UID against the signed-in Firebase account email before rollout.

In the pilot chat, `/legacy` immediately selects the existing meal bot and blocks
future agent writes; `/agent` opts back in only when the operator flag is enabled.
A rollout generation and per-user preference epoch invalidate old queued turns
when the pilot is disabled/re-enabled or the user leaves/rejoins. The global disable flag affects queued turns and is checked transactionally at
meal writes. It cannot undo a write committed before the switch was disabled.
If a pilot flag cannot be read, the pilot gets a retry message rather than having
a question accidentally treated as a meal. Non-pilot users are unaffected.

## Deploy / restore

```sh
firebase deploy --only functions:whatsappWebhook,functions:whatsappAgentWorker --project logcal-ai --non-interactive --force
```

Fast rollback: disable the flag, or send `/legacy` from the pilot account.
Then send a new message. New agent state is never used by the existing bot.

Full code rollback, if necessary:

```sh
node functions/scripts/whatsapp-agent.cjs disable
node functions/scripts/whatsapp-agent.cjs rollback-code
```

The script disables the pilot, verifies and extracts the original source archive into a temporary
directory, installs the pinned dependencies, and deploys only whatsappWebhook.
It does not check out another branch, reset local work, redeploy app functions,
restore the database, or remove previously saved meals. Disable the agent first
so the separate worker does not continue queued actions. The worker can remain
deployed and disabled. Old secret versions are not copied into source control.

## Reliability and limits

The webhook creates an inbox record and returns; a Firestore onCreate worker does
the agent work. A per-user queue/lease orders messages. Meal writes, sync records,
and their inbox audit result commit together. The global flag, user override,
account linkage, and pending selected date are rechecked inside that transaction.
Each inbound message can save at most one meal; multiple foods can be one meal.
Agent and legacy paths share deterministic meal IDs. The router recognizes prior
agent inbox events before considering legacy fallback, so redelivered questions
cannot become legacy meals after rollback.
The worker retries up to three processing attempts; model rounds/tool calls and
query range are bounded. No model failure falls through to legacy meal logging.

The last 12 short conversation entries are used for up to 24 hours. History,
queue, leases, preferences, and inbox data use separate backend-only collections
covered by the existing deny-all rule. Nutrition queries use the authenticated
linked UID, at most 92 days/500 records, with deterministic sums and labelled
logged-day/calendar-day averages, missing macros, and truncation. Models do not
receive raw credentials or a tool argument for choosing another UID.

The pilot doesn't provide web research for coaching. Branded meal estimation
continues to use existing account model/search settings. Workout coaching is
based on what the user shares, not device history. Transcription uses the same speech model with an agent-specific prompt that
preserves questions and exercise vocabulary; app meal dictation is unchanged. A crash after sending a reply but before recording its
delivery may duplicate a reply; deterministic meal writes prevent duplicate meals.
Conversation records currently have no automated retention deletion policy.

## Acceptance tests

Run `npm --prefix functions test`. All existing legacy tests must pass. Test the
agent with “How much protein did I log yesterday?”, a hypothetical meal, a mixed
log-and-question request, a voice question, a captionless food photo, a workout
request, and “Actually, make that one banana” using the meal's Edit button.
Use `/legacy` and `/agent`, and verify the operator disable flag stops writes.

## Validation completed before private activation

The full local suite passes, including the original legacy tests and the archived
production-definition checks. Live OpenAI smoke tests used fixture-only tools for
a personal data question, mixed logging + question, and workout coaching; they
made no database writes and sent no WhatsApp messages. The deployed operator flag
was enabled, disabled, and read back as disabled before activation. All five
existing non-WhatsApp functions retained their original deployed source reference.
Only the verified pilot account will be enabled for human WhatsApp testing.
The first worker deployment needs --force to accept its idempotent retry policy.
