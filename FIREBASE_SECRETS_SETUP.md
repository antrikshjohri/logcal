# Firebase Secrets Setup (Fixed)

The error you encountered was because `functions:config:set` is deprecated. We've updated the code to use **Firebase Secrets** (the modern, recommended approach).

## Quick Fix

### Step 1: Update `.firebaserc`
Replace `"your-project-id"` with your actual Firebase project ID:

```json
{
  "projects": {
    "default": "your-actual-project-id-here"
  }
}
```

### Step 2: Set API Key as Secret

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

When prompted, paste your OpenAI API key. This securely stores it in Firebase Secret Manager.

### Step 3: Deploy Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## What Changed

✅ **Before (deprecated):**
- Used `firebase functions:config:set` (requires Runtime Config API)
- Accessed via `functions.config().openai?.api_key`

✅ **After (modern):**
- Uses `firebase functions:secrets:set` (Firebase Secret Manager)
- Accessed via `process.env.OPENAI_API_KEY` in function
- Function declared with `functions.runWith({ secrets: ["OPENAI_API_KEY"] })`

## Benefits

- ✅ No need to enable Runtime Config API
- ✅ More secure (Firebase Secret Manager)
- ✅ Simpler setup
- ✅ Recommended by Firebase

## Verify Secret is Set

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

This will show the secret value (for verification only).

## Troubleshooting

**"Secret not found"**
- Make sure you ran: `firebase functions:secrets:set OPENAI_API_KEY`
- Verify with: `firebase functions:secrets:access OPENAI_API_KEY`

**"Permission denied"**
- Make sure you're logged in: `firebase login`
- Check you're using the correct project: `firebase use`

**Function deployment fails**
- Make sure secret is set before deploying
- Check `.firebaserc` has correct project ID

