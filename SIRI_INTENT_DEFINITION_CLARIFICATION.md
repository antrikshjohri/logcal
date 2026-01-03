# Intent Definition File - Clarification

## Understanding the Interface

When setting up your Intent Definition file, you'll see different fields:

### 1. Intent-Level Properties (Top Section)

**Category** - This is what you're looking for!
- **For Xcode 26.2+**: "Custom" is no longer available
- **Select**: **"Create"** category → **"Add"** (this represents adding/logging a meal)
  - Alternative: **"Generic"** → **"Do"** (if "Create" doesn't work for your use case)
- Make sure you select the **Intent itself** (not a parameter) in the left sidebar

**Title**: "Log a meal"
**Description**: "Log calories for a meal in LogCal"

### 2. Parameter-Level Properties (When Adding Parameters)

When you add a parameter and see the "Type" dropdown with categories like:
- Generic (Do, Run, Go)
- Information (View, Open)
- Create (Create, Add)
- etc.

**This is the Parameter's Semantic Type**, not the Intent Category.

**For your parameters:**
- **`foodDescription` parameter**:
  - **Type** (data type): Select **"String"** from the data type dropdown
  - **Type** (semantic - the one you're seeing): You can leave as default or ignore this. It's optional.
  
- **`mealType` parameter**:
  - **Type** (data type): Select **"String"**
  - **Type** (semantic): Leave as default

## Step-by-Step Visual Guide

1. **Select the Intent** in the left sidebar (should be named something like "Intent" or "LogMealIntent")

2. **In the right panel**, look for **"Category"** field at the top
   - This is separate from parameters
   - Should show a dropdown with options like: "Custom", "Order", "Information", etc.
   - Select **"Custom"**

3. **To add parameters:**
   - Look for **"Parameters"** section
   - Click the **"+"** button
   - A new parameter appears
   - Configure its properties:
     - **Display Name**: "Food Description"
     - **Type**: "String" (this is the data type - different from the semantic type dropdown)
     - **Input Type**: "Text"
     - **Prompt**: "What did you eat?"
     - **Required**: Check the box

## If You Can't Find "Custom" Category

The Intent Category might be:
- Called something else in your Xcode version
- Located in a different place
- Or you might need to:
  1. Select the Intent in the left sidebar (not a parameter)
  2. Look at the top of the right panel
  3. Find "Category" or "Intent Category" field

## Quick Checklist

- [ ] Intent selected in left sidebar (not a parameter)
- [ ] "Category" field visible in right panel (top section)
- [ ] Category set to "Custom" (or equivalent)
- [ ] Title: "Log a meal"
- [ ] Description: "Log calories for a meal in LogCal"
- [ ] Parameters added with correct data types (String)

## The Type Dropdown You're Seeing

The dropdown with categories (Generic, Information, Create, etc.) is for **semantic typing** of parameters. This is optional and helps Siri understand the context better. For your use case:

- You can **ignore it** and leave as default
- Or if you want to be specific:
  - For `foodDescription`: Leave as default or "Other"
  - For `mealType`: Leave as default

The important thing is that the **data Type** is "String" (not the semantic type dropdown).

