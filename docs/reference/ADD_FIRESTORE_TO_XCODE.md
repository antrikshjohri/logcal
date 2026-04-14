# How to Add FirebaseFirestore to Xcode Project

## Quick Steps

### Method 1: Through Package Dependencies (Recommended)

1. **Open Xcode** and open your project
2. **Select your project** (blue icon at the top of the navigator)
3. **Select your target** ("logcal" under TARGETS)
4. Click on **"Package Dependencies"** tab
5. Find **"firebase-ios-sdk"** in the list
6. Click the **arrow** next to it to expand
7. You'll see a list of products. Look for **FirebaseFirestore**
8. If it's unchecked, **check the box** next to it
9. Xcode will automatically update your project

### Method 2: Re-add the Package

If Method 1 doesn't work:

1. In Xcode, go to **File** → **Add Packages...**
2. In the search box, type: `https://github.com/firebase/firebase-ios-sdk`
3. If it's already added, you'll see it in the list
4. Click on **"firebase-ios-sdk"**
5. Click **"Add Package"** (or "Add to Project" if already added)
6. In the product selection screen, make sure these are checked:
   - ✅ FirebaseAuth
   - ✅ FirebaseCore
   - ✅ FirebaseFirestore ← **Make sure this is checked!**
   - ✅ FirebaseFunctions
   - ✅ FirebaseStorage
7. Click **"Add Package"**

### Method 3: Verify It's Added

After adding, verify:

1. In Xcode, select your project
2. Select your target
3. Go to **"General"** tab
4. Scroll down to **"Frameworks, Libraries, and Embedded Content"**
5. You should see **FirebaseFirestore** in the list

If you see it there, you're all set! ✅

## Verify in Code

You can also verify by checking if the import works:

1. Open any Swift file
2. Add this at the top: `import FirebaseFirestore`
3. If it compiles without errors, Firestore is properly added ✅

## Troubleshooting

**"No such module 'FirebaseFirestore'"**
- Make sure you followed Method 1 or 2 above
- Clean build folder: **Product** → **Clean Build Folder** (Shift+Cmd+K)
- Build again: **Product** → **Build** (Cmd+B)

**Can't find FirebaseFirestore in Package Dependencies**
- Make sure the firebase-ios-sdk package is added
- Try Method 2 to re-add the package

**Still not working?**
- Close and reopen Xcode
- Delete Derived Data: **Xcode** → **Settings** → **Locations** → Click arrow next to Derived Data path → Delete the folder for your project
- Rebuild the project

