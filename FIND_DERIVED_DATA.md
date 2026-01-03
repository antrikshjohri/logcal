# Finding Generated Intent Classes in DerivedData

## Quick Answer

Instead of searching DerivedData, let's verify the Intent Definition is properly configured in Xcode. That's the real issue.

## But If You Want to Check DerivedData

### Step 1: Find Your Project's DerivedData Folder

1. **In Xcode**: 
   - **File** → **Project Settings** (or **Workspace Settings**)
   - Click the arrow next to "Derived Data" path
   - This opens the DerivedData folder for your project

2. **Or manually**:
   - Path: `~/Library/Developer/Xcode/DerivedData/`
   - Look for folder starting with `logcal-` or containing your project name
   - Folder name is usually a hash like `logcal-abcdefghijklmnop/`

### Step 2: Look for Generated Files

Inside your project's DerivedData folder:
- `Build/Intermediates.noindex/LogCalIntent.build/`
- Look for generated `.swift` files

**But this is complex and not necessary!**

## Better Approach: Fix in Xcode

The real issue is the Intent Definition isn't being compiled. Let's fix it properly:

### Method 1: Verify Intent Definition Settings

1. **Select** `LogCalIntent.intentdefinition` in Project Navigator
2. **File Inspector** (right panel)
3. **Target Membership**:
   - ✅ `logcal` checked
   - ✅ `LogCalIntents` checked (THIS IS CRITICAL!)

### Method 2: Check Build Phases

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Look for **"Compile Intent Definition Files"** section
   - If it exists, `LogCalIntent.intentdefinition` should be listed
   - If it doesn't exist, that's the problem!

### Method 3: Add to Build Phases Manually

1. **Select `LogCalIntents` target**
2. **Build Phases** tab
3. Click **"+"** at top → **"New Copy Files Phase"**
4. **Destination**: "Resources"
5. Click **"+"** → Add `LogCalIntent.intentdefinition`
6. **Code Sign On Copy**: ✅ Checked

### Method 4: Check Build Settings (May Not Appear)

**Note**: "Intent Definition" might not appear in Build Settings in some Xcode versions. This is normal - skip this method if you don't see it.

1. **Select `LogCalIntents` target**
2. **Build Settings** tab
3. Search for **"Intent Definition"** or **"INTENT"**
4. If it appears, should show `LogCalIntent.intentdefinition`
5. **If it doesn't appear**: That's okay - use Method 1 or 2 instead

## Most Likely Issue

The Intent Definition file is **not being compiled** for the extension target. 

**Quick Fix:**
1. Select `LogCalIntent.intentdefinition`
2. File Inspector → Target Membership
3. Make sure `LogCalIntents` is checked
4. Clean Build Folder (⌘⇧K)
5. Build extension (⌘B)

## Alternative: Check Build Log

1. **Build the extension** (⌘B)
2. **View build log** (click the build icon in top bar)
3. **Search for** "LogCalIntent" or "intentdefinition"
4. Look for errors or warnings about Intent Definition compilation

## If Still Not Working

The Intent Definition might need to be in a different location or configured differently. Try:

1. **Move Intent Definition** to extension folder temporarily
2. **Add it back** to both targets
3. **Clean and rebuild**

But first, verify Target Membership - that's usually the issue!

