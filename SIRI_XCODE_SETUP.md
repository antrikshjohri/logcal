# Siri Integration - Xcode Setup Instructions

## Step 1: Create Intent Definition File

1. **In Xcode**: File → New → File
2. **Select**: iOS → Resource → SiriKit Intent Definition File
3. **Name**: `LogCalIntent.intentdefinition`
4. **Save to**: `logcal/` directory (same level as `ContentView.swift`)

### Configure the Intent:

1. **Click the "+" button** at bottom left to add a new Intent
2. **Set Intent Properties** (in the right panel):
   - **Category**: Select **"Create"** category, then choose **"Add"** (this represents adding/logging a meal)
     - Alternative: You can use **"Generic"** → **"Do"** if "Create" doesn't fit your needs
   - **Title**: "Log a meal"
   - **Description**: "Log calories for a meal in LogCal"
   - **Supported by**: Your App

3. **Add Parameters** (click "+" next to "Parameters" section):
   
   **Parameter 1: `foodDescription`**
   
   **Basic Properties:**
   - **Display Name**: "Food Description"
   - **Type**: **"String"** (select from dropdown)
   - **Array**: ❌ Unchecked
   - **Configurable**: ✅ **Checked** (allows editing in Shortcuts)
   - **Resolvable**: ✅ **Checked** (Siri will ask for this value)
   - **Dynamic Options**: ❌ Unchecked
   
   **Siri Dialog Section** (expand if collapsed):
   - **Prompt**: **"What did you eat?"** (this is what Siri will ask)
   - **Customize disambiguation dialog**: ❌ Unchecked
   
   **Input Section:**
   - **Default Value**: Leave empty
   - **Multiline**: ❌ Unchecked
   
   **Keyboard Section:**
   - **Capitalization**: "Sentences" (default)
   - All disable options: ❌ Unchecked
   
   **Parameter 2: `mealType`** (Optional - add another parameter)
   
   **Basic Properties:**
   - **Display Name**: "Meal Type"
   - **Type**: **"String"**
   - **Array**: ❌ Unchecked
   - **Configurable**: ✅ **Checked**
   - **Resolvable**: ✅ **Checked** (Siri can ask if not provided)
   - **Dynamic Options**: ❌ Unchecked
   
   **Siri Dialog Section:**
   - **Prompt**: **"What meal is this?"** (optional)
   - **Customize disambiguation dialog**: ❌ Unchecked
   
   **Input Section:**
   - **Default Value**: Leave empty
   - **Multiline**: ❌ Unchecked

4. **Configure Response** (Response section):

   **How to find it:**
   - Select your **Intent** in the left sidebar (not a parameter)
   - In the right panel, look for **"Response"** section/tab
   - It should be below "Parameters" section
   - If you don't see it, it might be collapsed - look for a disclosure triangle or "Response" header
   
   **Success Response:**
   - **Title**: "Logged {calories} calories"
     - The `{calories}` will be replaced with the actual value
   - **Subtitle**: "Meal logged successfully"
   
   **Failure Response:**
   - **Title**: "Failed to log meal"
   - **Subtitle**: "{errorMessage}"
     - The `{errorMessage}` will be replaced with the actual error

5. **Add Response Properties** (in Response section):

   Click the **"+"** button next to "Response" or "Response Properties" to add:
   
   **Property 1: `calories`**
   - **Display Name**: "Calories"
   - **Type**: **"Integer"** or **"Double"** (Number)
   - This will hold the logged calorie count
   
   **Property 2: `mealType`**
   - **Display Name**: "Meal Type"
   - **Type**: **"String"**
   - This will hold the meal type (breakfast, lunch, etc.)
   
   **Property 3: `message`**
   - **Display Name**: "Message"
   - **Type**: **"String"**
   - This will hold the success message
   
   **Property 4: `errorMessage`**
   - **Display Name**: "Error Message"
   - **Type**: **"String"**
   - This will hold error messages if logging fails
   
   **Note**: These properties are what your Intent Handler code will set in the response. The `{calories}` and `{errorMessage}` in the response titles use these properties.

## Step 2: Create Intents Extension Target

1. **In Xcode**: File → New → Target
2. **Select**: iOS → Intents Extension
3. **Product Name**: `LogCalIntents`
4. **Bundle Identifier**: `com.serene.logcal.LogCalIntents`
5. **Language**: Swift
6. **Include UI Extension**: ❌ No (we don't need custom UI)

### Configure Extension Target:

1. **Select the `LogCalIntents` target** in Project Navigator
2. **General Tab**:
   - **Deployment Target**: iOS 17.6 (match main app)
   - **Supported Destinations**: iPhone

3. **Signing & Capabilities**:
   - Enable **App Groups** (create new: `group.com.serene.logcal`)
   - Add **Siri** capability

4. **Info.plist** (for extension):
   - Add key: `NSSupportsLiveActivities` = `NO`
   - Add key: `NSUserActivityTypes` = Array with `LogMealIntent`

## Step 3: Add Files to Extension Target

The following files need to be added to **both** the main app target and the extension target:

### Files to Share:

1. **Models**:
   - `logcal/Models/MealEntry.swift`
   - `logcal/Models/MealLogResponse.swift`

2. **Services** (create shared versions):
   - `logcal/Services/FirebaseService.swift`
   - `logcal/Services/FirestoreService.swift`
   - `logcal/Utils/AppError.swift`

3. **Extension-specific files** (extension target only):
   - `logcal/IntentsExtension/IntentHandler.swift`
   - `logcal/IntentsExtension/ExtensionMealService.swift`
   - `logcal/IntentsExtension/MealTypeInferenceHelper.swift`

### How to Add Files to Multiple Targets:

1. **Select a file** in Project Navigator
2. **Open File Inspector** (right panel)
3. **Under "Target Membership"**:
   - ✅ Check `logcal` (main app)
   - ✅ Check `LogCalIntents` (extension)

**Do this for**:
- `MealEntry.swift`
- `MealLogResponse.swift`
- `FirebaseService.swift`
- `FirestoreService.swift`
- `AppError.swift`
- `Constants.swift` (if extension needs it)

## Step 4: Configure Extension's Info.plist

1. **Open**: `LogCalIntents/Info.plist`
2. **Add**:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <false/>
   <key>NSUserActivityTypes</key>
   <array>
       <string>LogMealIntent</string>
   </array>
   ```

## Step 5: Update Extension's IntentHandler

1. **Open**: `LogCalIntents/IntentHandler.swift` (auto-generated)
2. **Replace** with the code from `logcal/IntentsExtension/IntentHandler.swift`
3. **Make sure** the extension can import:
   - `Intents`
   - `Foundation`
   - `FirebaseAuth`
   - `FirebaseFirestore`

## Step 6: Add Firebase to Extension

1. **Select** `LogCalIntents` target
2. **Build Phases** → **Link Binary With Libraries**
3. **Add**:
   - `FirebaseAuth.framework`
   - `FirebaseFirestore.framework`
   - `FirebaseFunctions.framework`

4. **Copy `GoogleService-Info.plist`** to extension:
   - Drag `GoogleService-Info.plist` into `LogCalIntents` folder
   - ✅ Check "Copy items if needed"
   - ✅ Add to `LogCalIntents` target

## Step 7: Update Main App for User Vocabulary

Add this to your main app's initialization (in `logcalApp.swift`):

```swift
import Intents

// In your app's init or onAppear
func setupSiriVocabulary() {
    let vocabulary = INVocabulary.shared()
    
    // Register app name
    vocabulary.setVocabularyStrings(["LogCal"], of: .workoutActivityName)
    
    // Register intent phrases
    let phrases = [
        "log my calories",
        "log calories",
        "log meal",
        "log breakfast",
        "log lunch",
        "log dinner",
        "log snack"
    ]
    vocabulary.setVocabularyStrings(phrases, of: .workoutActivityName)
}
```

## Step 8: Test on Real Device

⚠️ **Important**: Siri Intents **do not work in the iOS Simulator**. You must test on a real device.

1. **Connect iPhone** to Mac
2. **Select device** in Xcode scheme
3. **Build and Run** both targets:
   - Main app (`logcal`)
   - Extension (`LogCalIntents`)
4. **On device**: Settings → Siri & Search → LogCal → Enable "Use with Siri"
5. **Test**: Say "Hey Siri, log my calories through LogCal"

## Step 9: Handle Intent in Main App (Optional)

If you want the main app to handle intents when opened:

1. **In `logcalApp.swift`**:
```swift
.onContinueUserActivity("LogMealIntent") { userActivity in
    // Handle intent when app is opened from Siri
    if let intent = userActivity.interaction?.intent as? LogMealIntent {
        // Navigate to HomeView or show logged meal
    }
}
```

## Troubleshooting

### "Intent not recognized"
- Check that Intent Definition file is added to both targets
- Verify `NSUserActivityTypes` in extension's Info.plist
- Ensure user enabled Siri for your app in Settings

### "Extension crashes"
- Check that all shared files are added to extension target
- Verify Firebase is properly configured in extension
- Check console logs for specific errors

### "Authentication fails"
- Ensure Firebase Auth is initialized in extension
- Check that `GoogleService-Info.plist` is in extension bundle

### "Can't find MealEntry/MealLogResponse"
- Verify files are added to extension target membership
- Check imports in extension files

## Next Steps

After setup:
1. Test basic intent flow
2. Add error handling
3. Improve Siri responses
4. Add more intent parameters (date, time, etc.)

