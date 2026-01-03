# Fix: Generated Intent Classes Not Found in Extension

## The Problem

The Intent Definition file is correct (Intent named `LogMealIntent`), but the extension can't find the generated classes:
- `LogMealIntent`
- `LogMealIntentResponse`
- `LogMealIntentHandling`

This happens when the generated classes are in the main app's module but not accessible to the extension.

## Solution 1: Check Intent Definition Code Generation Settings

1. **Open** `LogCalIntent.intentdefinition`
2. **Select your Intent** (`LogMealIntent`) in left sidebar
3. **Look for** "Class Generation Language" or similar setting in File Inspector
4. **Make sure it's set to** "Swift"
5. **Also check** if there's a "Target" or "Generate Classes For" setting
   - Both targets should be selected

## Solution 2: Import the Generated Module (Try This!)

The generated Intent classes might be in the main app's module. Try importing it:

1. **Open** `LogCalIntents/IntentHandler.swift`
2. **Add this import** at the top:
   ```swift
   import logcal  // Import main app module
   ```
3. **Build** (⌘B)

If that doesn't work, try:
```swift
@_implementationOnly import logcal
```

## Solution 3: Move Intent Definition to Shared Location

1. **Create a new folder** at the project root level (not inside any target folder)
2. **Move** `LogCalIntent.intentdefinition` to this shared folder
3. **Add to both targets**:
   - Select the file
   - File Inspector → Target Membership
   - Check both `logcal` and `LogCalIntents`
4. **Clean and rebuild**

## Solution 4: Duplicate Intent Definition (Nuclear Option)

If nothing else works:

1. **Copy** `LogCalIntent.intentdefinition` to `LogCalIntents/` folder
2. **Add** the copy to extension target only:
   - Check `LogCalIntents`
   - Uncheck `logcal`
3. **Keep original** in main app with:
   - Check `logcal`
   - Uncheck `LogCalIntents`
4. **Clean and rebuild**

This gives each target its own Intent Definition, generating classes for each.

## Solution 5: Check Build Order

1. **Select your project** in Project Navigator
2. **Select main app target** (`logcal`)
3. **Build Phases** tab
4. **Check "Dependencies"**:
   - `LogCalIntents` should NOT depend on `logcal`
5. **Select `LogCalIntents` target**
6. **Build Phases → Dependencies**
   - This should be empty or not include `logcal`

## Solution 6: Clean Everything and Rebuild

1. **Product** → **Clean Build Folder** (⌘⇧K)
2. **Close Xcode**
3. **Delete DerivedData**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/logcal-*
   ```
4. **Reopen Xcode**
5. **Build extension** (⌘B)

## Solution 7: Check Intent Definition File Inspector

1. **Select** `LogCalIntent.intentdefinition`
2. **File Inspector** (right panel)
3. **Look for**:
   - "Intent Classes" section
   - "Class Generation" option
   - Any dropdown for language or generation settings
4. **Ensure Swift is selected**

## Most Likely Fix

**Try Solution 2 first** - add `import logcal` to your IntentHandler.swift file. This imports the main app's module where the generated classes live.

If that doesn't work, **try Solution 4** - having separate Intent Definition files for each target.

## After Any Fix

1. **Clean Build Folder** (⌘⇧K)
2. **Build main app first** (select `logcal` scheme, ⌘B)
3. **Then build extension** (select `LogCalIntents` scheme, ⌘B)

Building the main app first ensures the Intent classes are generated before the extension tries to use them.

