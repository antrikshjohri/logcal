# How to Check Firebase Function Logs

The INTERNAL error (code 13) means the function is failing, but we need to see the actual error from the function logs.

## Option 1: Firebase Console (Recommended)

1. Go to: https://console.firebase.google.com/project/logcal-ai/functions/logs
2. Look for recent `logMeal` function calls
3. Click on a failed execution to see detailed logs
4. Look for lines starting with `ERROR:` or `DEBUG:` to see what's happening

## Option 2: Firebase CLI

```bash
# View recent logs
firebase functions:log

# View logs for specific function
firebase functions:log --only logMeal

# Follow logs in real-time
firebase functions:log --follow
```

## What to Look For

The logs should now show:
- `DEBUG: logMeal function called` - Confirms function is being invoked
- `DEBUG: API key is configured` - Confirms secret is accessible
- `ERROR: OPENAI_API_KEY is not set` - Means secret isn't accessible (need to redeploy)
- `ERROR: OpenAI API error` - Means OpenAI API call failed
- Any other error messages that explain what's failing

## Most Likely Issue

If you see `ERROR: OPENAI_API_KEY is not set`, it means:
1. The function was deployed **before** the secret was set, OR
2. The function needs to be **redeployed** after setting the secret

**Solution:** Redeploy the function:
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

