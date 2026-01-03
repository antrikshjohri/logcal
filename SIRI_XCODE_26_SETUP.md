# Siri Integration - Xcode 26.2+ Setup

## Important: Xcode 26.2 Changes

In Xcode 26.2, the Intent Definition interface has changed:
- **"Custom" category is no longer available**
- You must select from predefined categories: Generic, Information, Order, Start, Share, Create, Search, Download, Other

## Step 1: Create Intent Definition File

1. **In Xcode**: File → New → File
2. **Select**: iOS → Resource → SiriKit Intent Definition File
3. **Name**: `LogCalIntent.intentdefinition`
4. **Save to**: `logcal/` directory

## Step 2: Configure the Intent

1. **Click the "+" button** at bottom left to add a new Intent
2. **Select the Intent** in the left sidebar (not a parameter)
3. **In the right panel, set Intent Properties**:

   **Category & Type:**
   - **Category**: Select **"Create"** from the dropdown
   - **Type**: Select **"Add"** from the "Create" category
     - This represents adding/logging a meal entry
     - Alternative: If "Create" doesn't work, use **"Generic"** → **"Do"**
   
   **Other Properties:**
   - **Title**: "Log a meal"
   - **Description**: "Log calories for a meal in LogCal"
   - **Supported by**: Your App
   - **Confirmation**: Optional (leave default)
   - **Widget**: ✅ **Yes** (enable this if you plan to create widgets later)
     - This allows the intent to be used in Siri Shortcuts widgets
     - Even if you're creating WidgetKit widgets (different feature), enabling this won't hurt
     - You can always enable it later, but it's easier to enable now
   - **Configurable in Shortcut**: ✅ Yes (recommended)
   - **Suggestion**: Optional

## Step 3: Add Parameters

Click the **"+"** button next to "Parameters" section:

### Parameter 1: `foodDescription`

**Basic Properties:**
- **Display Name**: "Food Description"
- **Type**: **"String"** (select from dropdown)
- **Array**: ❌ Unchecked (Supports multiple values)
- **Configurable**: ✅ **Checked** (User can edit value in Shortcuts, widgets, and Add to Siri)
- **Resolvable**: ✅ **Checked** (Siri can ask for value when run)
- **Dynamic Options**: ❌ Unchecked (Options are provided dynamically)

**Input Section** (expand if collapsed):
- **Default Value**: Leave empty
- **Multiline**: ❌ Unchecked

**Keyboard Section** (expand if collapsed):
- **Capitalization**: "Sentences" (default is fine)
- **Disable autocorrect**: ❌ Unchecked
- **Disable smart quotes**: ❌ Unchecked
- **Disable smart dashes**: ❌ Unchecked

**Siri Dialog Section** (expand if collapsed):
- **Prompt**: **"What did you eat?"** (this is what Siri will ask)
- **Customize disambiguation dialog**: ❌ Unchecked

**Relationship:**
- **Parent Parameter**: None (leave as default)

### Parameter 2: `mealType` (Optional)

**Basic Properties:**
- **Display Name**: "Meal Type"
- **Type**: **"String"**
- **Array**: ❌ Unchecked
- **Configurable**: ✅ **Checked**
- **Resolvable**: ✅ **Checked** (Siri can ask if not provided)
- **Dynamic Options**: ❌ Unchecked

**Input Section:**
- **Default Value**: Leave empty
- **Multiline**: ❌ Unchecked

**Keyboard Section:**
- **Capitalization**: "Sentences" (default)
- All disable options: ❌ Unchecked

**Siri Dialog Section:**
- **Prompt**: **"What meal is this?"** (optional - Siri will ask if needed)
- **Customize disambiguation dialog**: ❌ Unchecked

**Relationship:**
- **Parent Parameter**: None

## Step 4: Configure Response

**You found it!** Select **"Response"** in the left sidebar (you should see it listed under your Intent).

### Step 4a: Add Response Properties

In the **Properties** section (top of the Response panel):

1. Click the **"+"** button to add properties
2. For each property, configure:

**Property 1: `calories`**
- **Display Name**: "Calories"
- **Type**: Select **"Integer"** or **"Double"** from dropdown
- This will hold the calorie count

**Property 2: `mealType`**
- **Display Name**: "Meal Type"
- **Type**: **"String"**
- This will hold the meal type

**Property 3: `message`**
- **Display Name**: "Message"
- **Type**: **"String"**
- This will hold success messages

**Property 4: `errorMessage`**
- **Display Name**: "Error Message"
- **Type**: **"String"**
- This will hold error messages

### Step 4b: Configure Response Templates

In the **Response Templates** section, you'll see two codes: **"success"** and **"failure"**

**For "success" code:**
1. Select **"success"** in the left Code box
2. In the right panel:
   - **Error**: ❌ Unchecked (this is NOT an error)
   - **Voice-Only Dialog**: Type **"Logged {calories} calories for your {mealType}"**
     - The `{calories}` and `{mealType}` are placeholders that use the properties you added
   - **Printed Dialog**: Type **"Meal logged successfully. {calories} calories for {mealType}."**
     - This is what appears in the Shortcuts app

**For "failure" code:**
1. Select **"failure"** in the left Code box
2. In the right panel:
   - **Error**: ✅ **Checked** (this IS an error response)
   - **Voice-Only Dialog**: Type **"Failed to log meal. {errorMessage}"**
   - **Printed Dialog**: Type **"Failed to log meal: {errorMessage}"**

### Step 4c: Output (Optional)

The **Output** section can be left as **"None"** for now. This is for more advanced use cases.

**Important Notes:**
- The `{calories}`, `{mealType}`, and `{errorMessage}` in the dialogs reference the properties you added
- Make sure property names match exactly (case-sensitive)
- Voice-Only Dialog is what Siri speaks
- Printed Dialog is what users see in Shortcuts app

## Step 4d: Configure Supported Combinations (Required)

**Important**: Xcode requires summaries for parameter combinations to prevent build errors.

1. **In the Intent Definition file**, look for **"Supported Combinations"** section
   - It should be in the right panel when the Intent is selected
   - Or look for it in the left sidebar under your Intent

2. **You should see**: `foodDescription, mealType` listed

3. **Select this combination** (it should be highlighted)

4. **In the Summary field** (right panel), type:
   ```
   Log meal: {foodDescription} for {mealType}
   ```
   - The `{foodDescription}` and `{mealType}` are placeholders that will show actual values
   - This is what appears in the Shortcuts app

5. **Preview** will update automatically to show how it looks

**Alternative Summary Options:**
- `Log {mealType}: {foodDescription}`
- `Log {foodDescription} as {mealType}`
- `{foodDescription} for {mealType}`

**Note**: This summary is required for the build to succeed. It's used in the Shortcuts app to show users what the intent does.

## Step 5: Verify Intent Name

- The Intent will be auto-named (e.g., "Intent" or "LogMealIntent")
- You can rename it in the left sidebar
- The class name will be: `LogMealIntent` (if you name it "LogMealIntent")

## Summary for Xcode 26.2

✅ **Category**: "Create" → "Add"  
✅ **Title**: "Log a meal"  
✅ **Description**: "Log calories for a meal in LogCal"  
✅ **Parameters**: `foodDescription` (String, required), `mealType` (String, optional)  
✅ **Response Properties**: `calories`, `mealType`, `message`, `errorMessage`  
✅ **Response Templates**: success and failure configured

---

## Step 5: Create Intents Extension Target

1. **In Xcode**: File → New → Target
2. **Select**: iOS → **Intents Extension**
3. **Product Name**: `LogCalIntents`
4. **Bundle Identifier**: `com.serene.logcal.LogCalIntents`
   - Xcode will auto-suggest this based on your main app bundle ID
5. **Language**: Swift
6. **Include UI Extension**: ❌ **No** (uncheck this - we don't need custom UI)
7. Click **Finish**

Xcode will:
- Create a new target
- Add it to your project
- Create `IntentHandler.swift` file
- Create `Info.plist` for the extension

## Step 6: Configure Extension Target

### 6a: General Settings

1. **Select `LogCalIntents` target** in Project Navigator (top of left sidebar)
2. **General Tab**:
   - **Deployment Target**: **iOS 17.6** (match your main app)
   - **Supported Destinations**: iPhone (iPad if needed)
   - **Display Name**: "LogCal Intents" (what users see)

### 6b: Signing & Capabilities

1. **Signing & Capabilities** tab:
   - **Team**: Select your development team (same as main app)
   - **Bundle Identifier**: Should be `com.serene.logcal.LogCalIntents`
   - **Automatically manage signing**: ✅ Checked

2. **Add Capabilities** (click "+ Capability"):
   - **App Groups**: 
     - Click "+ Capability" → Search "App Groups"
     - Add: `group.com.serene.logcal` (create new if needed)
     - This allows sharing data between app and extension
   - **Siri**: 
     - ✅ **Already included!** Intents Extensions automatically have Siri capability
     - You don't need to add it manually
     - If you don't see it in the list, that's normal - it's built into the extension

### 6c: Build Settings

1. **Build Settings** tab:
   - Search for "Swift Language Version"
   - Set to match your main app (likely Swift 5 or latest)

## Step 7: Add Intent Definition to Extension (CRITICAL!)

**This step is critical!** If skipped, you'll get "Cannot find type 'LogMealIntent'" errors.

### 7a: Check Target Membership

1. **Select** `LogCalIntent.intentdefinition` in Project Navigator
2. **Open File Inspector** (right panel, first icon)
3. **Under "Target Membership"**:
   - ✅ Check `logcal` (main app)
   - ✅ Check `LogCalIntents` (extension) - **MUST BE CHECKED!**

### 7b: Verify in Build Phases

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Expand **"Compile Sources"**
4. **Look for** `LogCalIntent.intentdefinition`
   - If it's NOT there, click **"+"** button
   - Navigate to and select `LogCalIntent.intentdefinition`
   - Click **Add**

### 7c: Clean and Build

1. **Product** → **Clean Build Folder** (⌘⇧K)
2. **Select scheme**: `LogCalIntents` (extension)
3. **Build** (⌘B)
4. This generates the Intent classes (`LogMealIntent`, `LogMealIntentResponse`, etc.)

**If you get "Cannot find type 'LogMealIntent'" errors:**
- The Intent Definition file is not being compiled for the extension
- Go back to Step 7a and 7b
- Make sure it's in both Target Membership AND Compile Sources

## Step 8: Add Shared Files to Extension Target

The extension needs access to your models and services. Add these files to **both** targets:

### Files to Share:

1. **Models**:
   - `logcal/Models/MealEntry.swift`
   - `logcal/Models/MealLogResponse.swift`

2. **Services**:
   - `logcal/Services/FirebaseService.swift` ✅ (extension uses this to call Firebase Functions)
   - `logcal/Services/FirestoreService.swift` ✅ (extension uses this to save meals)
   - `logcal/Utils/AppError.swift` ✅ (error handling)
   - `logcal/Utils/Constants.swift` ✅ (API configuration)

**Files NOT needed in extension:**
- ❌ `logcal/Services/OpenAIService.swift` - **NOT needed**
  - The extension uses `FirebaseService` which calls Firebase Functions
  - Firebase Functions handle the OpenAI API call internally
  - Extension doesn't need direct OpenAI access

### How to Add Files to Extension Target:

**Method 1: File Inspector**
1. Select a file in Project Navigator (e.g., `MealEntry.swift`)
2. Open **File Inspector** (right panel, first icon)
3. Under **"Target Membership"**:
   - ✅ Check `logcal` (main app)
   - ✅ Check `LogCalIntents` (extension)

**Method 2: Build Phases**
1. Select `LogCalIntents` target
2. **Build Phases** tab
3. Expand **"Compile Sources"**
4. Click **"+"** button
5. Add the files you need

**Do this for all files listed above.**

## Step 9: Add Extension-Specific Files

Add the files I created earlier to the extension:

1. **Copy these files** to your project (they're in `IntentsExtension/` folder):
   - `IntentHandler.swift` → Replace the auto-generated one
   - `ExtensionMealService.swift` → Extension-only
   - `MealTypeInferenceHelper.swift` → Extension-only

2. **In Project Navigator**:
   - Drag these files into the `LogCalIntents` folder/group
   - When prompted, make sure:
     - ✅ "Copy items if needed" is checked
     - ✅ **`LogCalIntents` target is checked** (extension target)
     - ❌ **`logcal` target is unchecked** (main app - these files are extension-only)

3. **Verify Target Membership** (after adding):
   - Select each file in Project Navigator
   - Open File Inspector (right panel)
   - Under "Target Membership":
     - ✅ `LogCalIntents` should be checked
     - ❌ `logcal` should be unchecked

**Important**: These files are **extension-only** and should NOT be in the main app target.

3. **Replace auto-generated `IntentHandler.swift`**:
   - The extension target has an auto-generated `IntentHandler.swift`
   - Replace its contents with the code from `IntentsExtension/IntentHandler.swift`
   - Make sure it imports:
     ```swift
     import Intents
     import Foundation
     import FirebaseAuth
     import FirebaseFirestore
     ```

## Step 10: Configure Extension's Info.plist

1. **Select `LogCalIntents` target**
2. Find `Info.plist` in the extension folder
3. **Right-click** → Open As → Source Code (or use Property List editor)

4. **Update the Info.plist** - Replace the entire contents with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key>
		<dict>
			<key>IntentsRestrictedWhileLocked</key>
			<array/>
			<key>IntentsSupported</key>
			<array>
				<string>LogMealIntent</string>
			</array>
		</dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.intents-service</string>
		<key>NSExtensionPrincipalClass</key>
		<string>$(PRODUCT_MODULE_NAME).IntentHandler</string>
	</dict>
	<key>NSSupportsLiveActivities</key>
	<false/>
	<key>NSUserActivityTypes</key>
	<array>
		<string>LogMealIntent</string>
	</array>
</dict>
</plist>
```

**Key Changes:**
- **IntentsSupported**: Changed from default message intents to `LogMealIntent`
- **NSUserActivityTypes**: Added with `LogMealIntent` (for app continuation)
- **NSSupportsLiveActivities**: Set to `false` (we don't use Live Activities)
- **Keep existing**: `NSExtensionPointIdentifier` and `NSExtensionPrincipalClass` stay the same

**Note**: `LogMealIntent` should match your Intent name exactly (case-sensitive). If you named it differently in the Intent Definition file, use that exact name.

## Step 11: Add Firebase to Extension

### 11a: Add Firebase Frameworks

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Expand **"Link Binary With Libraries"**
4. Click **"+"** button
5. Add:
   - `FirebaseAuth.framework`
   - `FirebaseFirestore.framework`
   - `FirebaseFunctions.framework`
   - `FirebaseCore.framework`

### 11b: Copy GoogleService-Info.plist

**Important**: You need to **copy** the file, not move it. The main app still needs it!

**Method 1: Using Finder (Recommended)**
1. **In Finder**, navigate to your project folder
2. Find `GoogleService-Info.plist` (in `logcal/` directory)
3. **Right-click** → **Duplicate** (or ⌘D)
4. **Rename** the copy to `GoogleService-Info.plist` (if needed)
5. **In Xcode**, right-click the `LogCalIntents` folder/group
6. Select **"Add Files to LogCalIntents..."**
7. Navigate to and select the **copied** `GoogleService-Info.plist`
8. In the dialog:
   - ✅ "Copy items if needed" (should be checked)
   - ✅ `LogCalIntents` target checked
   - ❌ `logcal` target unchecked

**Method 2: Using Xcode File Menu**
1. **In Xcode**, select the `LogCalIntents` folder/group
2. **File** → **Add Files to "LogCalIntents"...**
3. Navigate to `logcal/GoogleService-Info.plist`
4. In the dialog:
   - ✅ "Copy items if needed" (important - this creates a copy!)
   - ✅ `LogCalIntents` target checked
   - ❌ `logcal` target unchecked
5. Click **Add**

**Method 3: If File Was Moved (Fix It)**
If you accidentally moved it:
1. **Undo** (⌘Z) to move it back
2. Then use Method 1 or 2 above

**Verify Both Files Exist:**
- `logcal/GoogleService-Info.plist` (main app - should still exist)
- `LogCalIntents/GoogleService-Info.plist` (extension - the copy)

### 11c: Initialize Firebase in Extension

The extension needs Firebase initialized. Update `IntentHandler.swift`:

```swift
import FirebaseCore

class IntentHandler: INExtension, LogMealIntentHandling {
    
    override init() {
        super.init()
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // ... rest of your code
}
```

## Step 12: Update Intent Handler Code

Make sure your `IntentHandler.swift` matches the Intent name. Since you renamed it to `LogMealIntent`, the code should reference:

```swift
func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
    // ... your code
}
```

**Verify:**
- The Intent class name matches: `LogMealIntent`
- The Response class name matches: `LogMealIntentResponse`
- Property names match what you configured: `calories`, `mealType`, `message`, `errorMessage`

## Step 13: Build and Test

### 13a: Build Both Targets

1. **Select scheme**: Choose `logcal` (main app) from scheme dropdown
2. **Build** (⌘B) - should succeed
3. **Select scheme**: Choose `LogCalIntents` (extension) from scheme dropdown
4. **Build** (⌘B) - should succeed

### 13b: Fix Common Build Errors

**Error: "Cannot find type 'LogMealIntent'"**
- Make sure `LogCalIntent.intentdefinition` is added to extension target
- Clean build folder (⌘⇧K) and rebuild

**Error: "Missing Firebase frameworks"**
- Check Step 11a - frameworks must be linked

**Error: "GoogleService-Info.plist not found"**
- Check Step 11b - file must be copied to extension

**Error: "Cannot find 'MealEntry' or 'MealLogResponse'"**
- Check Step 8 - files must be added to extension target

### 13c: Test on Real Device

⚠️ **Important**: Siri Intents **do NOT work in iOS Simulator**. You must test on a real device.

1. **Connect iPhone** to Mac
2. **Select device** in scheme dropdown (not simulator)
3. **Build and Run** main app first (⌘R)
4. **Build and Run** extension (select `LogCalIntents` scheme, then ⌘R)
5. **On device**: 
   - Settings → Siri & Search → LogCal
   - Enable **"Use with Siri"**
6. **Test**: Say "Hey Siri, log my calories through LogCal"

## Step 14: Verify Intent Handler Integration

Your `IntentHandler.swift` should:
1. Handle `LogMealIntent`
2. Call `ExtensionMealService.shared.logMeal()`
3. Return `LogMealIntentResponse` with:
   - `calories` property set
   - `mealType` property set
   - `message` property set (for success)
   - `errorMessage` property set (for failure)
4. Use response code: `.success` or `.failure`

## Troubleshooting

### Intent not recognized by Siri
- Check Settings → Siri & Search → LogCal → "Use with Siri" is enabled
- Rebuild and reinstall both app and extension
- Restart device

### Extension crashes
- Check console logs for specific errors
- Verify Firebase is initialized in extension
- Check all shared files are in extension target

### "Missing or insufficient permissions" (Firestore)
- Check Firestore rules allow authenticated writes
- Verify Firebase Auth is working in extension

### Meals not appearing in main app
- Extension saves to Firestore
- Main app syncs from Firestore on launch
- Check `SyncHandlerView` is syncing properly

## Next Steps After Setup

1. ✅ Test basic intent flow
2. ✅ Verify meals appear in app after Siri logging
3. ✅ Test error handling
4. ✅ Improve Siri responses if needed
5. ✅ Consider adding more intent parameters (date, time, etc.)

## Summary Checklist

- [ ] Intent Definition file created and configured
- [ ] Intents Extension target created
- [ ] Extension configured (signing, capabilities)
- [ ] Intent Definition added to extension target
- [ ] Shared files added to extension target
- [ ] Extension-specific files added
- [ ] Firebase configured in extension
- [ ] GoogleService-Info.plist copied to extension
- [ ] Intent Handler code updated
- [ ] Both targets build successfully
- [ ] Tested on real device
- [ ] Siri recognizes intent
- [ ] Meals sync to main app

