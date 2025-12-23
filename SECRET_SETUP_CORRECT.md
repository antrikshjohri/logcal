# Correct Way to Set Firebase Secret

## The Issue
You ran:
```bash
firebase functions:secrets:set sk-svcacct-1OTipnbyM-...
```

This is **wrong** - you're using the API key as the secret name.

## Correct Command

Run this command:
```bash
firebase functions:secrets:set OPENAI_API_KEY
```

**Note:** Just `OPENAI_API_KEY` - no value after it.

## What Will Happen

1. Firebase will prompt: `? Enter a value for OPENAI_API_KEY:`
2. **Then** paste your API key (it will start with `sk-` and be a long string)
3. Press Enter

## Current Prompt

If you're still seeing the prompt asking about using the converted key name:
- Answer: **No** (or press Ctrl+C to cancel)
- Then run the correct command above

