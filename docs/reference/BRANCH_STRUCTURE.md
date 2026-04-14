# Branch Structure & Cleanup Guide

## Current Branch Status

### Active Branches

1. **`main`** (commit: `f6dadb5`)
   - **Status**: Main production branch
   - **Contains**: Core app features, history view enhancements
   - **Location**: Behind `firebase-support` and `clean-logs-refactor`

2. **`firebase-support`** ⭐ (CURRENT - commit: `cacf194`)
   - **Status**: Latest work - Firebase backend integration
   - **Contains**: 
     - Firebase Functions
     - Firebase Auth (anonymous)
     - Optional Firestore support
     - All previous features from main
   - **Location**: Ahead of `main` by 3 commits
   - **Action**: Should be merged to `main` when ready

3. **`clean-logs-refactor`** (commit: `6e09df6`)
   - **Status**: Engineering improvements
   - **Contains**: 
     - Constants file
     - Error Banner component
     - Code refactoring
   - **Location**: Ahead of `main` by 2 commits
   - **Action**: Can be merged to `main` or `firebase-support`

### Stale/Completed Branches

4. **`feature/logs-enhancement`** (commit: `f6dadb5`)
   - **Status**: Same as `main` - likely already merged
   - **Action**: Can be deleted

5. **`feature/daily-checkin`** (commit: `2728a51`)
   - **Status**: Older feature branch
   - **Contains**: Keyboard dismissal functionality
   - **Action**: Check if merged, then delete

6. **`bugfix`** (commit: `2728a51`)
   - **Status**: Same as `feature/daily-checkin`
   - **Action**: Likely duplicate, can be deleted

7. **`enhancements`** (commit: `37e1766`)
   - **Status**: Very old branch
   - **Action**: Check if merged, then delete

## Branch Relationship Diagram

```
main (f6dadb5)
  │
  ├─ feature/logs-enhancement (f6dadb5) [SAME AS MAIN - DELETE]
  │
  ├─ clean-logs-refactor (6e09df6) [AHEAD BY 2 COMMITS]
  │   └─ firebase-support (cacf194) [AHEAD BY 3 COMMITS] ⭐ CURRENT
  │
  ├─ feature/daily-checkin (2728a51) [BEHIND - CHECK IF MERGED]
  ├─ bugfix (2728a51) [SAME AS daily-checkin - DELETE]
  └─ enhancements (37e1766) [OLD - CHECK IF MERGED]
```

## Recommended Cleanup Strategy

### Option 1: Merge Everything to Main (Recommended)

1. **Merge `firebase-support` to `main`** (includes everything):
   ```bash
   git checkout main
   git merge firebase-support
   git push origin main
   ```

2. **Delete merged branches**:
   ```bash
   git branch -d feature/logs-enhancement
   git branch -d bugfix
   git branch -d clean-logs-refactor  # If firebase-support has all its changes
   git push origin --delete feature/logs-enhancement
   git push origin --delete bugfix
   ```

3. **Keep `firebase-support`** for now (until main is updated)

### Option 2: Keep Feature Branches Separate

If you want to keep branches for different features:

1. **Keep `main`** as stable production
2. **Keep `firebase-support`** for Firebase work
3. **Delete duplicates**: `feature/logs-enhancement`, `bugfix`
4. **Check and delete old branches**: `enhancements`, `feature/daily-checkin`

## Current State Analysis

### What's in Each Branch

- **`main`**: Core features, history view with grouping
- **`firebase-support`**: Everything in main + Firebase backend
- **`clean-logs-refactor`**: Engineering improvements (Constants, ErrorBanner)

### What Should Happen Next

1. **Immediate**: Merge `firebase-support` → `main` (it has all the latest work)
2. **Cleanup**: Delete duplicate/merged branches
3. **Future**: Create new feature branches from `main` as needed

## Commands to Clean Up

### Check if branches are merged:
```bash
# Check which branches are merged into main
git branch --merged main

# Check which branches are merged into firebase-support
git branch --merged firebase-support
```

### Safe deletion (only deletes if merged):
```bash
git branch -d feature/logs-enhancement
git branch -d bugfix
git branch -d enhancements
```

### Force deletion (if not merged but you're sure):
```bash
git branch -D feature/logs-enhancement
```

### Delete remote branches:
```bash
git push origin --delete feature/logs-enhancement
git push origin --delete bugfix
```

## Recommended Workflow Going Forward

1. **`main`** = Production-ready code
2. **`firebase-support`** = Current feature branch (merge to main when ready)
3. **New features** = Create from `main`: `git checkout -b feature/new-feature main`

## Next Steps

1. ✅ Review this document
2. 🔄 Merge `firebase-support` to `main` when Firebase is stable
3. 🧹 Clean up duplicate/old branches
4. 📝 Update `main` to be the latest stable version

