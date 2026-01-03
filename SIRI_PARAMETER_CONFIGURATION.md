# Siri Intent Parameter Configuration Guide

## Understanding the Parameter Configuration Window

When you select a parameter in the Intent Definition file, you'll see a detailed configuration panel with multiple sections. Here's what each section means:

## Parameter Configuration Sections

### 1. Basic Properties (Top Section)

**Display Name**
- What users see in Shortcuts app
- Example: "Food Description"

**Type**
- Data type dropdown: String, Integer, Double, Boolean, Date, etc.
- For food description: Select **"String"**

**Array**
- "Supports multiple values" checkbox
- ✅ Checked = parameter accepts multiple values (array)
- ❌ Unchecked = single value (default)
- For food description: ❌ **Unchecked** (single meal at a time)

**Configurable**
- "User can edit value in Shortcuts, widgets, and Add to Siri"
- ✅ Checked = Users can modify the value before running
- ❌ Unchecked = Value is fixed
- For food description: ✅ **Checked** (users should be able to edit)

**Resolvable**
- "Siri can ask for value when run"
- ✅ Checked = Siri will prompt user if value is missing
- ❌ Unchecked = Siri won't ask, will fail if missing
- For food description: ✅ **Checked** (required - Siri must ask)

**Dynamic Options**
- "Options are provided dynamically"
- ✅ Checked = Options come from your code at runtime
- ❌ Unchecked = Static options (default)
- For food description: ❌ **Unchecked** (free text input)

### 2. Relationship Section

**Parent Parameter**
- Links this parameter to another parameter
- Usually: "None" (no relationship)
- Used for hierarchical data (e.g., city depends on country)

### 3. Input Section (Expand to see)

**Default Value**
- Pre-filled value if user doesn't provide one
- For food description: Leave **empty** (required field)

**Multiline**
- Allows multi-line text input
- For food description: ❌ **Unchecked** (single line is fine)

### 4. Keyboard Section (Expand to see)

**Capitalization**
- Dropdown: None, Words, Sentences, All Characters
- Default: "Sentences"
- For food description: **"Sentences"** (default is fine)

**Disable autocorrect**
- Prevents iOS autocorrect
- For food description: ❌ **Unchecked** (autocorrect is helpful)

**Disable smart quotes**
- Prevents converting quotes to smart quotes
- For food description: ❌ **Unchecked** (default is fine)

**Disable smart dashes**
- Prevents converting dashes to em-dashes
- For food description: ❌ **Unchecked** (default is fine)

### 5. Siri Dialog Section (Expand to see)

**Prompt**
- **This is what Siri will say to the user!**
- Example: "What did you eat?"
- This is the most important field for user experience
- For food description: **"What did you eat?"**

**Customize disambiguation dialog**
- Allows custom dialog when Siri needs clarification
- For food description: ❌ **Unchecked** (default dialog is fine)

### 6. Validation Errors Section

- Shows any configuration errors
- Should show "Validation Errors (0)" when configured correctly
- If errors appear, fix them before proceeding

## Recommended Configuration for `foodDescription`

```
Display Name: "Food Description"
Type: String
Array: ❌ Unchecked
Configurable: ✅ Checked
Resolvable: ✅ Checked
Dynamic Options: ❌ Unchecked

Siri Dialog → Prompt: "What did you eat?"
Input → Default Value: (empty)
Input → Multiline: ❌ Unchecked
Keyboard → Capitalization: Sentences
```

## Recommended Configuration for `mealType` (Optional)

```
Display Name: "Meal Type"
Type: String
Array: ❌ Unchecked
Configurable: ✅ Checked
Resolvable: ✅ Checked (optional - Siri can ask if not provided)
Dynamic Options: ❌ Unchecked

Siri Dialog → Prompt: "What meal is this?" (optional)
Input → Default Value: (empty)
Input → Multiline: ❌ Unchecked
Keyboard → Capitalization: Sentences
```

## Key Points

1. **Prompt is critical** - This is what Siri says to users
2. **Resolvable must be checked** for required parameters
3. **Configurable should be checked** to allow user editing
4. **Expand collapsed sections** to see all options
5. **Validation Errors** should be 0 when done correctly

## Common Mistakes

❌ **Forgetting to set Prompt** - Siri won't know what to ask
❌ **Unchecking Resolvable for required fields** - Intent will fail
❌ **Not expanding Siri Dialog section** - Missing the Prompt field
❌ **Setting wrong Type** - Should be "String" for text input

