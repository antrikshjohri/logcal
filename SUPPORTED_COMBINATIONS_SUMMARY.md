# Supported Combinations Summary - Fix Build Error

## The Error

```
LogMealIntent: The shortcut suggestion with 'foodDescription, mealType' parameter combination must have a summary.
```

## What This Means

Xcode requires a **summary** for each parameter combination in your Intent. This summary is shown in the Shortcuts app to help users understand what the intent does.

## How to Fix

### Step 1: Find Supported Combinations

1. **Open** your `LogCalIntent.intentdefinition` file
2. **Select your Intent** in the left sidebar (LogMealIntent)
3. **Look for "Supported Combinations"** section:
   - It might be in the right panel
   - Or in the left sidebar under your Intent
   - Or in a separate tab/section

### Step 2: Select the Combination

You should see:
- `foodDescription, mealType` listed

**Select this combination** (it should highlight when clicked)

### Step 3: Add Summary

In the **Summary** field (right panel), type:

```
Log meal: {foodDescription} for {mealType}
```

**What this does:**
- `{foodDescription}` - Placeholder for the food description
- `{mealType}` - Placeholder for the meal type
- Shows in Shortcuts app as: "Log meal: chicken sandwich for lunch"

### Step 4: Preview Updates

The **Preview** section will automatically update to show:
- How it looks in Shortcuts app
- What parameters are shown
- What's in "More Options"

## Example Summaries

You can use any of these formats:

1. **Simple**:
   ```
   Log meal: {foodDescription} for {mealType}
   ```

2. **Alternative**:
   ```
   Log {mealType}: {foodDescription}
   ```

3. **Descriptive**:
   ```
   Log {foodDescription} as {mealType}
   ```

4. **Minimal**:
   ```
   {foodDescription} for {mealType}
   ```

## What Shows in Shortcuts App

After adding the summary, users will see in Shortcuts app:

```
Log meal: [their food description] for [their meal type]
```

For example:
- "Log meal: grilled chicken breast for lunch"
- "Log meal: oatmeal with fruits for breakfast"

## Important Notes

- ✅ **Summary is required** - Build will fail without it
- ✅ **Use placeholders** - `{foodDescription}` and `{mealType}` reference your parameters
- ✅ **Case-sensitive** - Parameter names must match exactly
- ✅ **Preview updates** - You can see how it looks before building

## If You Don't See Supported Combinations

1. **Build the project** (⌘B) - Sometimes it appears after first build
2. **Check Intent is selected** - Not a parameter, but the Intent itself
3. **Look in different tabs** - It might be in a separate section
4. **Check Xcode version** - Some versions show it differently

## After Adding Summary

1. **Save** the Intent Definition file
2. **Build again** (⌘B) - Error should be gone
3. **Verify** - Preview should show the summary

## Troubleshooting

**Error persists after adding summary:**
- Make sure you saved the file
- Clean build folder (⌘⇧K) and rebuild
- Check parameter names match exactly (case-sensitive)

**Can't find Supported Combinations:**
- Try building first - it might appear after build
- Check if Intent Definition file is properly added to targets
- Look in different sections of the Intent editor

