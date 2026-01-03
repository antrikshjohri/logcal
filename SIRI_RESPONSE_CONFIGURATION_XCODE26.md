# Response Configuration for Xcode 26.2

## Overview

In Xcode 26.2, the Response section has three main parts:
1. **Properties** - Define what data the response contains
2. **Output** - Advanced output configuration (usually "None")
3. **Response Templates** - Define what Siri says and what users see

## Step-by-Step Configuration

### 1. Select Response in Left Sidebar

- Click on **"Response"** (with blue 'R' icon) under your Intent
- You should see it listed under "CUSTOM INTENTS" in the left sidebar

### 2. Add Response Properties

In the **Properties** section (top section):

1. Click the **"+"** button
2. A property appears - configure it:
   - **Display Name**: What users see
   - **Type**: Data type (String, Integer, Double, etc.)

**Add these 4 properties:**

| Display Name | Type | Purpose |
|-------------|------|---------|
| Calories | Integer or Double | Holds calorie count |
| Meal Type | String | Holds meal type (breakfast, lunch, etc.) |
| Message | String | Success message |
| Error Message | String | Error message if logging fails |

### 3. Configure Response Templates

In the **Response Templates** section:

You'll see two codes in the left "Code" box:
- **success** (for successful meal logging)
- **failure** (for errors)

#### Configure "success" Template:

1. **Select "success"** in the Code box
2. In the right panel:
   - **Error**: ❌ **Unchecked** (this is success, not an error)
   - **Voice-Only Dialog**: 
     ```
     Logged {calories} calories for your {mealType}
     ```
     - This is what Siri will **speak** to the user
     - `{calories}` and `{mealType}` reference the properties you added
   
   - **Printed Dialog**:
     ```
     Meal logged successfully. {calories} calories for {mealType}.
     ```
     - This is what appears in the **Shortcuts app**
     - More detailed than voice dialog

#### Configure "failure" Template:

1. **Select "failure"** in the Code box
2. In the right panel:
   - **Error**: ✅ **Checked** (this IS an error)
   - **Voice-Only Dialog**:
     ```
     Failed to log meal. {errorMessage}
     ```
     - What Siri will **speak** when there's an error
   
   - **Printed Dialog**:
     ```
     Failed to log meal: {errorMessage}
     ```
     - What appears in **Shortcuts app** on error

### 4. Output Section

- Leave as **"None"** (default)
- This is for advanced use cases
- You don't need to change this

## Property Placeholders

When you use `{propertyName}` in the dialogs:
- It must match the **Display Name** of a property you added
- Case-sensitive
- Examples:
  - `{calories}` → References "Calories" property
  - `{mealType}` → References "Meal Type" property
  - `{errorMessage}` → References "Error Message" property

## Example Configuration

### Properties:
```
1. Calories (Integer)
2. Meal Type (String)
3. Message (String)
4. Error Message (String)
```

### Success Template:
- Error: ❌ Unchecked
- Voice-Only: "Logged {calories} calories for your {mealType}"
- Printed: "Meal logged successfully. {calories} calories for {mealType}."

### Failure Template:
- Error: ✅ Checked
- Voice-Only: "Failed to log meal. {errorMessage}"
- Printed: "Failed to log meal: {errorMessage}"

## Important Notes

1. **Property names must match** - `{calories}` in dialog must match "Calories" property
2. **Error checkbox** - Must be checked for failure, unchecked for success
3. **Voice vs Printed** - Voice is shorter (Siri speaks it), Printed is more detailed (Shortcuts app)
4. **Output** - Can stay as "None" for most use cases

## Testing

After configuration:
1. Build your project (⌘B)
2. The Intent Handler code will set these properties
3. Siri will use the Voice-Only Dialog
4. Shortcuts app will show the Printed Dialog

