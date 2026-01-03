# How to Verify Intent Definition is Configured Correctly

## The Real Test: Does It Build?

The best way to verify is to **build and see if errors are gone**. But here are ways to check:

## Method 1: Target Membership (Most Important!)

1. **Select** `LogCalIntent.intentdefinition` in Project Navigator
2. **File Inspector** (right panel, first icon)
3. **Target Membership** section:
   - ✅ `logcal` should be checked
   - ✅ `LogCalIntents` should be checked ← **CRITICAL!**

**If `LogCalIntents` is NOT checked:**
- Check it
- Save
- Clean Build Folder (⌘⇧K)
- Build extension (⌘B)

## Method 2: Check Build Phases

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Look for these sections (in order):
   - **"Compile Intent Definition Files"** (if it exists)
   - **"Compile Sources"**
   - **"Copy Bundle Resources"**

4. **Check each section**:
   - If "Compile Intent Definition Files" exists, `LogCalIntent.intentdefinition` should be there
   - If it doesn't exist, that's okay - Intent Definitions might compile automatically

## Method 3: Build and Check Errors

1. **Select `LogCalIntents` scheme**
2. **Build** (⌘B)
3. **Check for errors**:
   - ✅ If no "Cannot find type 'LogMealIntent'" errors → It's working!
   - ❌ If you still get those errors → Go back to Method 1

## Method 4: Check Intent Definition File Location

The file should be:
- ✅ In `logcal/` folder (main app source)
- ✅ Added to both targets (main app + extension)
- ✅ Not moved to extension folder only

## Method 5: Verify Intent Name

1. **Open** `LogCalIntent.intentdefinition`
2. **Select Intent** in left sidebar
3. **Check name** - should be exactly `LogMealIntent`
4. **Your code** uses `LogMealIntent` - names must match exactly!

## Quick Checklist

- [ ] Intent Definition file exists in `logcal/` folder
- [ ] Target Membership: Both `logcal` and `LogCalIntents` checked
- [ ] Intent name is exactly `LogMealIntent`
- [ ] Cleaned build folder (⌘⇧K)
- [ ] Built extension target (⌘B)
- [ ] No "Cannot find type" errors

## If Still Not Working

Try this nuclear option:

1. **Remove** `LogCalIntent.intentdefinition` from extension target:
   - Select file → File Inspector → Uncheck `LogCalIntents`
2. **Add it back**:
   - Select file → File Inspector → Check `LogCalIntents`
3. **Clean Build Folder** (⌘⇧K)
4. **Build** (⌘B)

Sometimes Xcode needs to "re-see" the file to compile it properly.

## Alternative: Check Build Log

1. **Build the extension** (⌘B)
2. **Click the build icon** in top bar (shows build status)
3. **Expand the build log**
4. **Search for** "LogCalIntent" or "intentdefinition"
5. **Look for**:
   - ✅ "Compiling Intent Definition" → Good!
   - ❌ Errors about Intent Definition → Problem found
   - ❌ No mention of Intent Definition → Not being compiled

## Most Common Issue

**Target Membership not checked for extension** - This is 90% of cases!

Fix: File Inspector → Target Membership → Check `LogCalIntents`

