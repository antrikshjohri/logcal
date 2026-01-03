# Finding the Response Section in Intent Definition

## Where is the Response Section?

The Response section is part of the **Intent configuration**, not the parameter configuration.

### Step-by-Step to Find It:

1. **Select the Intent** in the left sidebar
   - Click on your Intent name (e.g., "Intent" or "LogMealIntent")
   - **NOT** on a parameter (like "foodDescription")
   - The Intent should be at the top level in the left sidebar

2. **Look in the Right Panel**
   - With the Intent selected, the right panel shows Intent properties
   - Scroll down past these sections:
     - Basic properties (Category, Title, Description)
     - Parameters section
   - **Response section** should be below Parameters

3. **If You Don't See It:**
   - It might be **collapsed** - look for a disclosure triangle (▶) or "Response" header
   - Click to expand it
   - In some Xcode versions, sections can be collapsed by default

## What the Response Section Looks Like

When you find it, you should see:

```
Response
├── Success Response
│   ├── Title: [text field]
│   └── Subtitle: [text field]
├── Failure Response
│   ├── Title: [text field]
│   └── Subtitle: [text field]
└── Response Properties
    └── [+ button to add properties]
```

## Common Issues

### "I can't find Response section"
- ✅ Make sure you selected the **Intent** (not a parameter)
- ✅ Scroll down in the right panel
- ✅ Look for collapsed sections (disclosure triangles)
- ✅ Check if there's a "Response" tab or section header

### "Response section is empty"
- That's normal! You need to:
  1. Add response properties first (click "+")
  2. Then configure the success/failure response titles

### "I see Response but no properties"
- Click the **"+"** button in the Response Properties section
- Add each property one by one

## Visual Guide

```
Left Sidebar          Right Panel
├── Intent ◄─────────┐
│   ├── Parameters   │  Intent Properties:
│   └── Response     │  ├── Category: Create
│                    │  ├── Title: "Log a meal"
│                    │  ├── Parameters:
│                    │  │   └── foodDescription
│                    │  └── Response: ◄── HERE!
│                       │   ├── Success Response
│                       │   ├── Failure Response
│                       │   └── Response Properties
```

## Alternative: Check Intent Class

If you still can't find it:
1. Build your project (⌘B)
2. Xcode will generate the Intent class
3. Check the generated code - it will show what response properties are available
4. The Response section might appear after the first build

## Quick Checklist

- [ ] Intent is selected (not parameter)
- [ ] Scrolled down past Parameters
- [ ] Checked for collapsed sections
- [ ] Looked for "Response" header/tab
- [ ] Built project once (sometimes helps)

## If Still Not Found

The Response section is **required** for Siri Intents. If you absolutely cannot find it:
1. Try creating a new Intent Definition file
2. Check Xcode version compatibility
3. The Response section should always be present for custom intents

