# WhatsApp voice meal logging

Linked users can send a WhatsApp voice note to log a meal. The webhook downloads
the media using the existing WhatsApp access token, transcribes it with
`gpt-transcribe`, and sends the resulting text through meal logging.
The confirmation includes the transcript. Text meals and voice notes receive ⏳
while processing, replaced by ✅ after saving or ⚠️ if processing fails. Reaction
requests have a five-second timeout and cannot fail meal logging. Menu/linking
flows do not receive meal progress reactions. A failed confirmation after saving
keeps ✅ and explains that the meal was saved. Spoken words do not execute account
commands; linking, unlinking, and menu commands remain text/button actions.

Audio is limited to 4 MB, including a streaming download limit. OGG/Opus voice
notes retain the `.ogg` extension. Unsupported attachments such as raw AAC receive
a request to send a WhatsApp-recorded voice note. No converter is installed.
Audio bytes are held in memory and are not saved by this implementation.
The transcript is saved as the meal's `foodText`.

The webhook checks account linkage before downloading or transcribing. It follows
the existing `ENABLE_CUSTOM_RATE_LIMITS` setting (currently disabled). Media lookup,
download, and transcription have individual timeouts. The webhook uses 512 MB
memory and a 300-second timeout.

Meal IDs are deterministic UUIDs derived from the user and WhatsApp message ID.
Both Firestore meal copies are committed in one transaction; repeated/concurrent
deliveries cannot create another meal for the same message. Concurrent deliveries
can still incur duplicate model calls before that transaction. Processing remains
synchronous: there is no durable background queue or guaranteed retry of a failed
confirmation reply. A durable queue/outbox is a separate reliability improvement.

## Verification

From `functions`, run `npm test`. The tests mock Meta, OpenAI, and Firestore and
exercise the exported webhook, download limits, and existing text/button flows.
They do not verify deployed credentials, real audio decoding, or live delivery.

## Deployment and live check

No new secrets are needed. The function still requires `OPENAI_API_KEY`,
`WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_VERIFY_TOKEN`, and `WHATSAPP_PHONE_NUMBER_ID`.
Media retrieval uses Graph API v23.0. The WhatsApp token must be authorized to
retrieve media belonging to the configured phone number.

Deploy the webhook from the Firebase project root:

```sh
firebase deploy --only functions:whatsappWebhook
```

With a linked WhatsApp number, send a short voice note such as “two bananas”.
Verify that the reply quotes the transcript, contains calories/macros, and the app
shows exactly one meal. Also check a normal text meal and the Main Menu button.
This deployment also contains the shared transcription helper's 60-second request
timeout; deploy `transcribeAudio` separately if that timeout is desired in the
already-deployed callable function.

## Meal photos

The webhook also handles WhatsApp `image` messages (camera or gallery), with or
without a caption. It downloads the JPEG/PNG with the same authenticated media
flow, enforces a 5 MB streaming limit, checks the file signature, and supplies a
MIME-correct data URL to the shared meal vision function. The caption is supplied
as context and cannot run account commands. An image-only meal uses the detected
item names as its saved description. Both meal copies have `hasImage: true`.

Image logging uses the linked account's existing model/search settings, progress
reactions, atomic deduplication, and itemized confirmation. Download/analysis
failures receive an actionable reply. Image bytes are used in memory for analysis;
the original photo is not stored or synced to the apps by this implementation.
The estimated nutrition and item breakdown are synced as usual. Each incoming
photo is treated as a separate meal; multiple photos are not grouped into one meal.

For a live check, send a food photo without a caption, then another with portion
context in its caption. Verify the itemized reply and one saved meal per photo.

## Edit and Delete meal

New meal confirmations have three buttons: **Edit meal**, **Delete meal**, and
**Today's Progress**. Button IDs carry the meal UUID; the backend resolves it only
inside the currently linked user's meals. Old confirmations keep their original
buttons; log a new meal to test these actions.

**Edit meal** opens a 15-minute text correction session for the selected meal.
The bot names the meal and offers **Change food**, **Change date**, and **Cancel**.
Choose Change food to type a correction; typing one directly also works. Send a short
correction (up to 2,000 characters), such as “Make the rice half a bowl”. The
existing refinement function receives the saved structured estimate and correction,
using the account's model/search settings. Image and voice meals can be edited
using their existing estimate; corrections themselves must be text. While editing,
photos/voice notes prompt for text or cancellation, rather than logging a new meal.
Menu, Help, Summary, or Unlink also leave edit mode. Expired edits release fresh voice/photo messages and ordinary meal text to normal
logging for today. Explicit correction text asks the user to select Edit meal
again rather than logging the correction as a new meal.

The backend updates the same meal ID and both cloud copies atomically, preserving
its timestamps, image flag, and other metadata. It rejects an edit if the meal was
deleted or changed during estimation, or the edit session was cancelled/replaced.
Message receipts prevent webhook retries from reapplying corrections or creating
new meals after a session ends. They are backend-only user subcollections covered
by the existing default-deny Firestore rule; no rules deployment is required.
Failed corrections can be retried by sending a new message while the session is
active. The implementation does not provide a background queue or automatic
recovery for an interrupted model request.

**Delete meal** immediately soft-deletes that specific meal and its mealLogs copy.
It is excluded from today's summary and existing app deletion sync. Repeated taps
are harmless. It cannot be edited after deletion.

Both app sync services now merge content changes in existing cloud meals, in
addition to deletions. These native changes require new iOS/Android app builds;
deploying the webhook alone cannot change installed app behavior. The apps keep
phone edits on the device until Firestore confirms the upload. If the upload
fails, History shows **Retry sync** on the affected meal.

Live checks: log two different meals, edit the older one's portion, and confirm
only that record changes. Cancel an edit and then log a new meal. Delete one meal
and check Today's Progress excludes it. On updated native builds, sync and verify
both the corrected and deleted states appear in the apps.

## Date selection (IST)

The main menu has **Log for another day**. Select **Today**, **Yesterday**, or
**Other date**. Other date asks for an unambiguous date including the year, e.g.
`15 Oct 2026`, `15 October 2026`, or `2026-10-15`. Impossible dates, ambiguous
numeric forms, and future dates are rejected. Date choices show the full selected
calendar date before the user sends text, voice, or a photo. The selection expires
in 15 minutes; Cancel or menu navigation clears it.

A selected date applies to one successfully saved meal. It survives download or
model failures. The meal transaction consumes it atomically with both meal copies;
concurrent meals cannot both use it, and a changed/cancelled selection cannot be
silently overwritten. Expired selections clear automatically before fresh voice/photo messages or
ordinary meal descriptions, which are logged for today with the date shown in
the confirmation. Explicit date replies and stale date buttons still prompt for
a new selection rather than being logged as meals. Stale choice buttons cannot
affect a replacement date selection.

Backdated meals without a known time are recorded at noon IST. Their creation time
is still now. If the description/transcript/caption explicitly says breakfast,
lunch, dinner, or snack, that meal type is used; otherwise historical meals are
labelled Meal rather than inferred from the current hour. Each confirmation shows
the full calendar date. Without a date selection, meals continue to use today.

**Edit meal → Change date** offers the same choices for the specific meal. It
changes only the meal timestamp (keeping its IST time of day) and updatedAt,
preserves its nutrition/creation time/photo flag, and updates mealLogs atomically.
It makes no AI call. Today's summary immediately reflects meals moved into or out
of today. The earlier native sync fixes are still required in installed app builds
to refresh dates of meals already downloaded locally.

Live checks: choose Yesterday from the menu, log a meal, then log another meal
without choosing a date and verify it uses today. Move the older meal to today
using Edit meal → Change date and check Today's Progress. Repeat with a custom
date, a photo, a voice note, cancellation, and a failed request followed by retry.

### Returning after an abandoned selection

Expiration is checked before reserving the inbound message as an edit action.
Expired state is cleared transactionally, without consuming a fresh meal message.
That message proceeds through the usual text/voice/photo logging path for today.
Explicit correction text after an expired edit, standalone dates, and expired
picker buttons are still handled as stale actions, with receipts preventing a
retry from accidentally logging them as meals. A concurrent replacement session
is preserved. The interrupted voice note that previously received an expiry
message was not logged; the user must resend it.
