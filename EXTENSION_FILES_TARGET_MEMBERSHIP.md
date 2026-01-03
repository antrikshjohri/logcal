# Extension Files - Target Membership Guide

## Quick Answer

**Extension-specific files should ONLY be in `LogCalIntents` target, NOT in `logcal` target.**

## File Categories

### 1. Shared Files (Both Targets)
These files are used by both the main app and extension:

- ✅ `MealEntry.swift` → Both targets
- ✅ `MealLogResponse.swift` → Both targets
- ✅ `FirebaseService.swift` → Both targets
- ✅ `FirestoreService.swift` → Both targets
- ✅ `AppError.swift` → Both targets
- ✅ `Constants.swift` → Both targets

**Target Membership:**
- ✅ `logcal` (main app)
- ✅ `LogCalIntents` (extension)

### 2. Extension-Only Files (Extension Target Only)
These files are ONLY for the extension:

- ✅ `IntentHandler.swift` → Extension only
- ✅ `ExtensionMealService.swift` → Extension only
- ✅ `MealTypeInferenceHelper.swift` → Extension only

**Target Membership:**
- ❌ `logcal` (main app) - **NOT needed**
- ✅ `LogCalIntents` (extension) - **Required**

### 3. Main App-Only Files (Main App Target Only)
These files are ONLY for the main app:

- ✅ `LogViewModel.swift` → Main app only
- ✅ `HomeView.swift` → Main app only
- ✅ `SpeechRecognitionService.swift` → Main app only
- ✅ All other ViewModels and Views → Main app only

**Target Membership:**
- ✅ `logcal` (main app) - **Required**
- ❌ `LogCalIntents` (extension) - **NOT needed**

## Why Extension Files Shouldn't Be in Main App

1. **IntentHandler.swift**: 
   - Implements `INExtension` protocol
   - Only used by Siri/Intents system
   - Not needed in main app

2. **ExtensionMealService.swift**:
   - Extension-specific service
   - Main app uses `LogViewModel` instead
   - Would cause conflicts if in both targets

3. **MealTypeInferenceHelper.swift**:
   - Simplified version for extension
   - Main app has full `MealTypeInference` service
   - Not needed in main app

## How to Check Target Membership

1. **Select a file** in Project Navigator
2. **Open File Inspector** (right panel, first icon)
3. **Look at "Target Membership"** section
4. **Check/uncheck** as needed

## Common Mistakes

❌ **Adding extension files to main app target**
- Causes build errors
- Creates duplicate symbols
- Unnecessary code in main app

❌ **Not adding shared files to extension**
- Extension can't access models/services
- Build will fail with "Cannot find type" errors

✅ **Correct approach**:
- Shared files → Both targets
- Extension files → Extension only
- Main app files → Main app only

## Quick Checklist

When adding files, ask:
1. **Is this used by the extension?** → Add to `LogCalIntents`
2. **Is this used by the main app?** → Add to `logcal`
3. **Is this used by both?** → Add to both

For extension-specific files:
- ✅ `LogCalIntents` target
- ❌ `logcal` target

