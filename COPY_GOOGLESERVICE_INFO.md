# How to Copy GoogleService-Info.plist to Extension

## Problem

When you drag `GoogleService-Info.plist` from the main app to the extension, Xcode **moves** it instead of copying it. This breaks the main app!

## Solution: Use Proper Copy Methods

### Method 1: Finder + Add Files (Recommended)

**Step-by-step:**

1. **Open Finder** and navigate to your project folder
   - Path: `/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/`

2. **Find the file**:
   - `logcal/GoogleService-Info.plist`

3. **Duplicate it**:
   - Right-click → **Duplicate** (or press ⌘D)
   - This creates `GoogleService-Info copy.plist`

4. **Rename the copy** (optional):
   - Right-click → Rename
   - Change to `GoogleService-Info.plist` (or keep as copy)

5. **In Xcode**:
   - Right-click the `LogCalIntents` folder/group
   - Select **"Add Files to LogCalIntents..."**
   - Navigate to and select the **duplicated file**
   - In the dialog:
     - ✅ "Copy items if needed" (should be checked)
     - ✅ `LogCalIntents` target checked
     - ❌ `logcal` target unchecked
   - Click **Add**

### Method 2: Xcode Add Files Menu

1. **In Xcode Project Navigator**:
   - Select the `LogCalIntents` folder/group

2. **File Menu**:
   - **File** → **Add Files to "LogCalIntents"...**

3. **Navigate and Select**:
   - Find `logcal/GoogleService-Info.plist`
   - Select it

4. **In the Dialog**:
   - ✅ **"Copy items if needed"** - **MUST BE CHECKED!**
     - This is the key - it creates a copy instead of moving
   - ✅ `LogCalIntents` target checked
   - ❌ `logcal` target unchecked

5. **Click Add**

### Method 3: If You Already Moved It

If you accidentally moved the file:

1. **Undo** (⌘Z) to move it back to main app
2. **Then use Method 1 or 2** to properly copy it

## Verify Both Files Exist

After copying, you should have:

1. **Main app file** (original):
   - Location: `logcal/GoogleService-Info.plist`
   - Target: `logcal` only
   - Should still be in Project Navigator under main app

2. **Extension file** (copy):
   - Location: `LogCalIntents/GoogleService-Info.plist`
   - Target: `LogCalIntents` only
   - Should appear in Project Navigator under extension

## Check Target Membership

To verify:

1. **Select** `logcal/GoogleService-Info.plist` in Project Navigator
2. **File Inspector** (right panel)
3. **Target Membership**:
   - ✅ `logcal` should be checked
   - ❌ `LogCalIntents` should be unchecked

4. **Select** `LogCalIntents/GoogleService-Info.plist`
5. **Target Membership**:
   - ❌ `logcal` should be unchecked
   - ✅ `LogCalIntents` should be checked

## Why Both Are Needed

- **Main app** needs it for Firebase initialization
- **Extension** needs it for Firebase initialization in the extension
- They're separate processes, so each needs its own copy

## Common Mistakes

❌ **Dragging file** → Moves it (breaks main app)
❌ **Not checking "Copy items if needed"** → Moves it
✅ **Using Add Files menu with "Copy items" checked** → Creates copy (correct!)

## Quick Checklist

- [ ] Original file still exists in `logcal/` folder
- [ ] Copy exists in `LogCalIntents/` folder
- [ ] Original has `logcal` target only
- [ ] Copy has `LogCalIntents` target only
- [ ] Both files are in Project Navigator

