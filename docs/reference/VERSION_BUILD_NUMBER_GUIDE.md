# Version and Build Number Best Practices

## Overview

iOS apps use two separate numbers:
- **Version Number** (Marketing Version / CFBundleShortVersionString): User-facing version (e.g., "1.0", "1.1", "2.0")
- **Build Number** (Current Project Version / CFBundleVersion): Internal build identifier (e.g., "1", "2", "100")

## Current Settings

Your app currently has:
- **Version**: 1.0
- **Build**: 1

## Best Practices

### Version Number (Marketing Version)

**When to increment:**
- ✅ **Major version** (1.0 → 2.0): Major feature releases, significant UI changes, breaking changes
- ✅ **Minor version** (1.0 → 1.1): New features, improvements, non-breaking changes
- ✅ **Patch version** (1.0.0 → 1.0.1): Bug fixes, small improvements (if using 3-part versioning)

**For App Store submissions:**
- **Must increment** if the new version has different features than the previous submission
- **Can stay the same** only if you're resubmitting the exact same build (e.g., after rejection)

**Recommendation:**
- Increment version for each App Store submission that includes changes
- Use semantic versioning: `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`

### Build Number (Current Project Version)

**When to increment:**
- ✅ **Every time** you create an archive for App Store submission
- ✅ **Every time** you create a TestFlight build
- ✅ **Every time** you create an Ad Hoc or Enterprise distribution
- ✅ **Must be unique** and **monotonically increasing** for each App Store submission

**For App Store submissions:**
- **Must increment** for every new build uploaded to App Store Connect
- **Cannot reuse** a build number that was already submitted (even if rejected)
- **Must be higher** than the previous build number

**Recommendation:**
- Use a simple incrementing number: 1, 2, 3, 4...
- Or use date-based: YYYYMMDD format (e.g., 20250115 for Jan 15, 2025)
- Or use timestamp: seconds since epoch

## Workflow Example

### Scenario 1: First App Store Submission
- Version: 1.0
- Build: 1
- Upload to App Store Connect

### Scenario 2: Bug Fix Before Release
- Version: 1.0 (same - no new features)
- Build: 2 (must increment)
- Upload new build

### Scenario 3: New Features Release
- Version: 1.1 (new features)
- Build: 3 (must increment)
- Upload to App Store Connect

### Scenario 4: Major Update
- Version: 2.0 (major changes)
- Build: 4 (must increment)
- Upload to App Store Connect

## Important Rules

1. **Build number must always increase** - App Store Connect will reject builds with duplicate or lower build numbers
2. **Version can stay the same** only if resubmitting the exact same code (rare)
3. **TestFlight builds** also require unique build numbers
4. **Build numbers are permanent** - once used, they cannot be reused

## Recommended Strategy

### For Your App:

**Option 1: Simple Incrementing (Recommended for most apps)**
- Version: 1.0, 1.1, 1.2, 2.0, etc. (increment when features change)
- Build: 1, 2, 3, 4, 5... (increment for every archive)

**Option 2: Date-Based Build Numbers**
- Version: 1.0, 1.1, 2.0, etc.
- Build: 20250115, 20250120, 20250201, etc. (YYYYMMDD format)

**Option 3: Version-Based Build Numbers**
- Version: 1.0
- Build: 1.0.1, 1.0.2, 1.0.3 (for bug fixes)
- Version: 1.1
- Build: 1.1.1, 1.1.2 (for new features)

## How to Update in Xcode

1. Select your project in Project Navigator
2. Select the **logcal** target
3. Go to **General** tab
4. Update:
   - **Version**: Marketing Version field
   - **Build**: Current Project Version field

Or edit `project.pbxproj`:
- `MARKETING_VERSION = 1.0;` → Version number
- `CURRENT_PROJECT_VERSION = 1;` → Build number

## For Your Next Submission

Since you're at Version 1.0, Build 1:

**If submitting a new build with changes:**
- Version: 1.0 (if only bug fixes) or 1.1 (if new features)
- Build: 2 (must increment)

**If resubmitting the same build:**
- Version: 1.0 (can stay same)
- Build: 2 (must increment - cannot reuse 1)

## Summary

✅ **Always increment Build number** for every archive/upload
✅ **Increment Version number** when features change
✅ **Build numbers must be unique and increasing**
✅ **Version can stay same** only for bug fix resubmissions

