# How to View Intents Extension Logs

## The Problem

Extension logs don't always appear in the main Xcode console. You need to view them separately.

## Method 1: Device Console (Recommended)

1. **Connect your device** to Mac
2. **Open Console.app** (Applications → Utilities → Console)
3. **Select your device** from the left sidebar
4. **Filter by**: Search for "LogCalIntents" or "IntentHandler"
5. **Run the shortcut** - logs should appear here

## Method 2: Xcode Console with Filter

1. **In Xcode**, open the **Console** (View → Debug Area → Activate Console, or ⌘⇧Y)
2. **At the bottom**, there's a filter/search box
3. **Type**: `LogCalIntents` or `[Siri]` to filter
4. **Run the shortcut** - filtered logs should appear

## Method 3: Check Extension Process

1. **In Xcode Console**, look for process name: `LogCalIntents`
2. Extension runs as a separate process
3. Logs might be prefixed with the process name

## Method 4: Use os_log (More Reliable)

If `print()` statements aren't showing, we can switch to `os_log` which is more reliable for extensions:

```swift
import os.log

let logger = OSLog(subsystem: "com.serene.logcal.LogCalIntents", category: "IntentHandler")
os_log("IntentHandler initialized", log: logger, type: .debug)
```

## Quick Test

1. **Run the shortcut**
2. **Check Console.app** on your Mac
3. **Search for**: "IntentHandler" or "LogCalIntents"
4. You should see the init() logs if the extension is loading

## If No Logs Appear

- Extension might not be installed
- Extension might be crashing before init()
- Check device logs in Console.app instead of Xcode

