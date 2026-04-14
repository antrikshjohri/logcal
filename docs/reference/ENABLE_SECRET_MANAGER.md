# Enable Secret Manager API - Quick Fix

## The Error
```
Permission denied to get service [secretmanager.googleapis.com]
```

This means the Secret Manager API isn't enabled for your Firebase project.

## Solution: Enable Secret Manager API

### Step 1: Open Google Cloud Console
Go to this URL (replace `logcal-ai` if your project ID is different):
```
https://console.cloud.google.com/apis/library/secretmanager.googleapis.com?project=logcal-ai
```

### Step 2: Enable the API
1. Click the **"Enable"** button
2. Wait 1-2 minutes for the API to be enabled

### Step 3: Set Your Secret
Once enabled, run:
```bash
firebase functions:secrets:set OPENAI_API_KEY
```
Paste your OpenAI API key when prompted.

### Step 4: Deploy
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Alternative: Use Environment Variables (Temporary)

If you want to test locally without enabling Secret Manager:

1. Create `functions/.env` file:
```bash
cd functions
echo "OPENAI_API_KEY=your-key-here" > .env
```

2. For local emulator testing, the `.env` file will be used automatically.

**Note:** For production deployment, you still need to enable Secret Manager API and use `firebase functions:secrets:set`.

## Verify API is Enabled

Check if it's enabled:
```bash
gcloud services list --enabled --project=logcal-ai | grep secretmanager
```

Or visit:
```
https://console.cloud.google.com/apis/dashboard?project=logcal-ai
```

Look for "Secret Manager API" in the list.

