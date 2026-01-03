# Fix: Cannot Find LogMealIntent Classes

## The Problem

The extension can't find the generated Intent classes:
- `LogMealIntent`
- `LogMealIntentResponse`
- `LogMealIntentHandling`

This happens when the Intent Definition file isn't properly compiled for the extension target.

## Solution Steps

### Step 1: Verify Intent Definition is in Extension Target (CRITICAL!)

1. **Select** `LogCalIntent.intentdefinition` in Project Navigator
2. **Open File Inspector** (right panel, first icon)
3. **Check "Target Membership"**:
   - ✅ `logcal` (main app) should be checked
   - ✅ `LogCalIntents` (extension) should be checked - **MUST BE CHECKED!**
   - If `LogCalIntents` is NOT checked:
     - ✅ Check it now
     - Save
     - Clean build folder (⌘⇧K)
     - Rebuild

**If this doesn't work, try Step 1b below.**

### Step 1b: Alternative - Check Build Phases for Intent Definition

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. **Look for** "Compile Intent Definition Files" section
   - If it exists, `LogCalIntent.intentdefinition` should be listed
   - If it doesn't exist, that might be the issue
4. **Also check** "Compile Sources" section
   - Intent Definition files might appear here in some Xcode versions

### Step 2: Verify Intent Definition Compilation

**Note**: "Intent Definition" might not appear in Build Settings in some Xcode versions. That's okay - use the build test instead.

**Option A: Check Build Phases**
1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Look for **"Compile Intent Definition Files"** section
   - If it exists, `LogCalIntent.intentdefinition` should be listed
   - If it doesn't exist, that's normal - Intent Definitions compile automatically

**Option B: Build and Test (Best Method)**
1. **Select `LogCalIntents` scheme**
2. **Build** (⌘B)
3. **Check for errors**:
   - ✅ No "Cannot find type" errors = Working!
   - ❌ Still getting errors = Go back to Step 1

### Step 3: Clean Build Folder

1. **Product** → **Clean Build Folder** (or ⌘⇧K)
2. This clears cached build artifacts

### Step 4: Build the Extension Target

1. **Select scheme**: `LogCalIntents` (extension)
2. **Build** (⌘B)
3. This should generate the Intent classes

### Step 5: Verify Intent Name Matches

1. **Open** `LogCalIntent.intentdefinition`
2. **Select your Intent** in left sidebar
3. **Check the name** - should be exactly `LogMealIntent`
   - If it's named differently (e.g., "Intent"), rename it to `LogMealIntent`
   - Right-click → Rename

### Step 6: Check Generated Files

After building, Xcode should generate:
- `LogMealIntent.swift` (in DerivedData)
- `LogMealIntentResponse.swift` (in DerivedData)

These are auto-generated and should be available to your code.

## Alternative: Check Intent Definition Location

The Intent Definition file should be:
- In the **main project** (not just extension)
- Added to **both targets** (main app and extension)
- At the root level or in a shared location

## If Still Not Working

### Method 1: Re-add Intent Definition

1. **Remove** `LogCalIntent.intentdefinition` from extension target
2. **Add it back**:
   - Select extension target
   - Build Phases → Compile Sources
   - Click "+" → Add `LogCalIntent.intentdefinition`
3. **Clean and rebuild**

### Method 2: Check Intent Definition Settings

1. **Select** `LogCalIntent.intentdefinition`
2. **File Inspector** → **Target Membership**
3. Make sure **both targets** are checked
4. **Build Settings** → Search "Intent Definition"
5. Should be set to compile for both targets

### Method 3: Verify Intent Name in Code

Make sure your `IntentHandler.swift` uses the exact Intent name:

```swift
// Should match the Intent name in .intentdefinition file
class IntentHandler: INExtension, LogMealIntentHandling {
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        // ...
    }
}
```

If your Intent is named differently, update the code to match.

## Common Issues

❌ **Intent Definition not in extension target**
- Fix: Add to extension target membership

❌ **Intent Definition not in Compile Sources**
- Fix: Add to Build Phases → Compile Sources

❌ **Intent name mismatch**
- Fix: Rename Intent to match code, or update code to match Intent name

❌ **Cached build artifacts**
- Fix: Clean build folder (⌘⇧K)

## Quick Checklist

- [ ] Intent Definition file is in both targets
- [ ] Intent Definition is in Compile Sources for extension
- [ ] Intent name is exactly `LogMealIntent`
- [ ] Cleaned build folder
- [ ] Built extension target
- [ ] Code uses correct Intent name

## After Fixing

1. **Clean Build Folder** (⌘⇧K)
2. **Build Extension** (select `LogCalIntents` scheme, then ⌘B)
3. **Errors should be gone**

If errors persist, the Intent Definition file might not be compiling. Check Xcode's build log for any Intent Definition compilation errors.

