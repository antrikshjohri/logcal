# Switch from lottie-ios to lottie-spm

## Why Switch?
According to the [lottie-spm repository](https://github.com/airbnb/lottie-spm), this package:
- Is much smaller (~500KB vs 300+ MB for lottie-ios)
- Downloads faster (uses precompiled XCFrameworks)
- Is specifically designed for Swift Package Manager
- More reliable for SPM integration

## Steps to Switch

### Step 1: Remove lottie-ios Package
1. Open your project in Xcode
2. Select your project in Project Navigator (top item)
3. Select the **logcal** target
4. Go to **General** tab
5. Scroll to **Frameworks, Libraries, and Embedded Content**
6. Find and remove:
   - **Lottie** (if present)
   - **Lottie-Dynamic** (if present)
7. Click the **-** button to remove each

### Step 2: Remove Package Dependency
1. Select your project in Project Navigator
2. Go to **Package Dependencies** tab (or **Swift Packages** in older Xcode)
3. Find **lottie-ios** in the list
4. Select it and click **-** to remove it
5. Confirm removal

### Step 3: Reset Package Cache
1. **File** → **Packages** → **Reset Package Caches**
2. **File** → **Packages** → **Resolve Package Versions**

### Step 4: Add lottie-spm Package
1. **File** → **Add Package Dependencies...**
2. Enter URL: `https://github.com/airbnb/lottie-spm.git`
3. Select version **4.5.2** (or latest)
4. Make sure **logcal** target is checked
5. Click **Add Package**

### Step 5: Verify Installation
1. Go to **General** tab → **Frameworks, Libraries, and Embedded Content**
2. You should see **Lottie** in the list
3. Set it to **Embed & Sign** (for dynamic) or **Do Not Embed** (for static)

### Step 6: Clean and Rebuild
1. **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. **Product** → **Build** (Cmd+B)

## Verify It Works
- Build should succeed without framework errors
- `import Lottie` should work in your code
- Animations should work at runtime

## Reference
- [lottie-spm GitHub Repository](https://github.com/airbnb/lottie-spm)

