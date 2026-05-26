# Favourite Meals PRD

## Use Cases

- **P0: Save just-logged meal**
  - From the post-log result screen, save the exact AI result as a reusable meal.

- **P0: Save from meal details**
  - From an existing meal detail screen, save that meal as a reusable meal.

- **P0: Log saved meal as-is**
  - From the Log screen, choose a saved meal and log it instantly with the same calories, macros, items, and meal type. No AI call.

- **P1: Edit saved meal before logging**
  - From a saved meal, prefill the log composer. If the user changes anything and logs, run the normal AI estimation flow.

- **P1: Manage saved meals**
  - View saved meals from Profile, rename them, and delete meals no longer needed.

## Decisions

- Saved meals are snapshots, not dynamic templates.
- Unchanged saved meals log instantly without AI.
- Any edited saved meal uses the existing AI logging flow.
- Portion multipliers are out of scope for MVP.
