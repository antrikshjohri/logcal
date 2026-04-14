# App Version Configuration Guide

This document explains how to configure the app version check system that prompts users to update when their app version is outdated.

## How It Works

1. **Version Check**: When a user taps "Log Meal", the app checks if their version meets the minimum required version stored in Firestore.
2. **Update Prompt**: If the version is outdated, an alert appears asking the user to update.
3. **Config Storage**: Configuration is stored in Firestore at `app/config` and cached locally for 1 hour.

## Firestore Configuration

### Step 1: Create the Config Document

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **"Start collection"** (if Firestore is new) or navigate to existing data
5. Create a collection named: `app`
6. Create a document with ID: `config`
7. Add the following fields:

```json
{
  "minimumAppVersion": "2.0",
  "updateMessage": "A new version of LogCal is available with exciting new features. Please update to continue using the app.",
  "appStoreURL": "https://apps.apple.com/app/id<YOUR_APP_ID>",
  "lastUpdated": <TIMESTAMP>
}
```

### Field Descriptions

- **`minimumAppVersion`** (String, Required): The minimum app version required. Uses semantic versioning (e.g., "1.0", "2.0", "2.1"). Users with versions below this will see the update prompt.
- **`updateMessage`** (String, Optional): Custom message to show in the update alert. If not provided, a default message is used.
- **`appStoreURL`** (String, Optional): Direct link to your app in the App Store. Format: `https://apps.apple.com/app/id<APP_ID>`. If not provided, the "Update Now" button won't open the App Store.
- **lastUpdated** (Timestamp, Optional): When the config was last updated (for tracking).

### Example Configurations

#### For Version 2.0 Release (Monetization)
```json
{
  "minimumAppVersion": "2.0",
  "updateMessage": "LogCal 2.0 is here! Update now to access premium features and continue logging meals.",
  "appStoreURL": "https://apps.apple.com/app/id1234567890",
  "lastUpdated": "2025-01-15T00:00:00Z"
}
```

#### For Current Version (No Update Required)
```json
{
  "minimumAppVersion": "1.0",
  "updateMessage": null,
  "appStoreURL": null,
  "lastUpdated": "2025-01-01T00:00:00Z"
}
```

## Version Comparison

The app uses semantic versioning comparison:
- `"1.0"` < `"2.0"` → Update required
- `"1.9"` < `"2.0"` → Update required
- `"2.0"` >= `"2.0"` → No update required
- `"2.1"` >= `"2.0"` → No update required

## Security Rules

The Firestore rules have been updated to allow public read access to `app/config`:

```javascript
// App configuration (public read, admin write only)
match /app/config {
  allow read: if true; // Anyone can read app config
  allow write: if false; // Only admins can write (set via Firebase Console)
}
```

**Important**: To update the config, you must use Firebase Console (not through the app). This prevents unauthorized changes.

## Testing

### Test Update Prompt

1. Set `minimumAppVersion` to `"2.0"` in Firestore
2. Run the app (which is version 1.0)
3. Tap "Log Meal"
4. You should see the update alert

### Test No Prompt

1. Set `minimumAppVersion` to `"1.0"` in Firestore
2. Run the app (which is version 1.0)
3. Tap "Log Meal"
4. The meal logging should proceed normally

## Deployment Checklist

Before releasing a new version that requires updates:

- [ ] Update `minimumAppVersion` in Firestore to the new version
- [ ] Add a custom `updateMessage` explaining the update
- [ ] Add `appStoreURL` with your App Store link
- [ ] Test the update prompt with the previous version
- [ ] Deploy updated Firestore rules (if not already deployed)
- [ ] Verify the config is readable (check Firebase Console)

## App Store URL Format

To get your App Store URL:
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Find your app
3. Copy the App Store URL
4. Format: `https://apps.apple.com/app/id<APP_ID>`

Or use the format: `https://apps.apple.com/app/logcal/id<APP_ID>`

## Notes

- Config is cached locally for 1 hour to reduce Firestore reads
- Version check happens only when user taps "Log Meal"
- Users can dismiss the alert and try again later
- The check is non-blocking for viewing existing data (only blocks new meal logging)

