# Fix Firebase Function INTERNAL Error

## The Error
```
Firebase Function error - Domain: com.firebase.functions, Code: 13, Description: INTERNAL
```

This means the Firebase Function is failing internally. Most likely causes:

## Most Common Issue: Secret Not Accessible

After setting a Firebase Secret, **you must redeploy the function** for it to access the secret.

### Solution:

1. **Verify the secret is set:**
   ```bash
   firebase functions:secrets:access OPENAI_API_KEY
   ```
   (You may need to run `firebase login --reauth` first if you get auth errors)

2. **Redeploy the function:**
   ```bash
   cd functions
   npm run build
   cd ..
   firebase deploy --only functions
   ```

3. **Test again** - The function should now have access to the secret.

## Check Firebase Console Logs

To see the actual error from the function:

1. Go to: https://console.firebase.google.com/project/logcal-ai/functions/logs
2. Look for recent `logMeal` function calls
3. Check the error messages - they'll show what's actually failing

## Common Issues:

1. **Secret not set:** Run `firebase functions:secrets:set OPENAI_API_KEY`
2. **Function not redeployed:** Must redeploy after setting secret
3. **OpenAI API error:** Check if your API key is valid
4. **Network error:** Function can't reach OpenAI API

## Quick Test

After redeploying, the function logs should show:
- `DEBUG: API key is configured (length: XX)` - This confirms the secret is accessible
- If you see `OPENAI API key not configured`, the secret isn't accessible

