# Lottie Animation Setup Guide

## Overview
This guide explains how to set up Lottie animations for the loading button and confetti effects.

## Step 1: Add Lottie Package (lottie-spm)

**Important:** Use `lottie-spm` instead of `lottie-ios` for Swift Package Manager. The `lottie-spm` package is smaller, faster to download, and uses precompiled XCFrameworks.

### If you already have lottie-ios installed:
1. In Xcode, select your project in Project Navigator
2. Select the **logcal** target
3. Go to **General** tab → **Frameworks, Libraries, and Embedded Content**
4. Remove **Lottie** and **Lottie-Dynamic** from the list
5. Go to **File** → **Packages** → **Reset Package Caches**
6. Go to **File** → **Packages** → **Resolve Package Versions**

### Add lottie-spm:
1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the package URL: `https://github.com/airbnb/lottie-spm.git`
4. Select version **4.5.2** or latest stable version
5. Add the package to the **logcal** target (main app target)
6. Click **Add Package**
7. You should see **Lottie** appear in "Frameworks, Libraries, and Embedded Content"
8. Set it to **Embed & Sign** (for dynamic framework) or **Do Not Embed** (for static)

## Step 2: Add Animation Files to Xcode Project

The animation files are already in `logcal/Animations/` folder:
- `LoadingAnimation.json`
- `ConfettiAnimation.json`

**Important:** You need to add these files to the Xcode project:

1. In Xcode, right-click on the `logcal` folder in the Project Navigator
2. Select **Add Files to "logcal"...**
3. Navigate to `logcal/Animations/` folder
4. Select both JSON files
5. **Make sure**:
   - ✅ "Copy items if needed" is checked (if files aren't already in the project)
   - ✅ "Create groups" is selected
   - ✅ **logcal** target is checked in "Add to targets"
6. Click **Add**

## Step 3: Verify Implementation

The following files have been created/updated:

### Created Files:
- `logcal/Views/Components/LottieView.swift` - SwiftUI wrapper for Lottie animations

### Updated Files:
- `logcal/Views/HomeView.swift` - Updated Log Meal button to show loading animation and added confetti overlay

## How It Works

### Loading Animation
- When user taps "Log Meal" and `isLoading` becomes `true`, the button:
  - Changes background to light gray (`Color.gray.opacity(0.3)`)
  - Replaces text with `LoadingAnimation.json`
  - Keeps the same button dimensions

### Confetti Animation
- When a meal is successfully logged (`latestResult` changes from `nil` to a value):
  - Confetti animation appears at the center of the screen
  - Animation size: 300x300 points
  - Plays once (not looping)
  - Auto-dismisses after 2 seconds
  - Overlays above all other content

## Testing

1. Build and run the app
2. Enter some food text
3. Tap "Log Meal" - you should see the loading animation on the button
4. After successful logging, you should see the confetti animation at the center

## Troubleshooting

### Animation not showing?
- Verify the JSON files are added to the Xcode project target
- Check that the file names match exactly: `LoadingAnimation.json` and `ConfettiAnimation.json`
- Ensure the files are in the `Animations` folder in the project navigator

### Build errors about Lottie?
- **Use `lottie-spm` instead of `lottie-ios`** - The SPM-specific package is more reliable
- Make sure Lottie package is added to the correct target
- If switching from `lottie-ios` to `lottie-spm`, remove the old package first
- Clean build folder: **Product** → **Clean Build Folder** (Shift+Cmd+K)
- Rebuild the project

### Animation files not found at runtime?
- Check that files are included in the app bundle:
  - Select the file in Xcode
  - Check the "Target Membership" in the File Inspector
  - Ensure **logcal** target is checked

