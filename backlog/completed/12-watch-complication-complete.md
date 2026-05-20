# Watch: Rep streak complication

**Status:** Complete  
**Effort:** M  
**Risk:** Low

## Problem

The streak lives inside the app. To feel it as passive daily accountability, it needs to be on the watch face — visible every time the user glances at their wrist, without opening anything.

This is the single biggest differentiator vs. other rep/streak apps: your streak number is always there.

## Change

### New target: `Just Reps Watch Widget`

Add a WidgetKit extension targeting watchOS. Supports three complication families:

| Family | Display |
|--------|---------|
| `.accessoryCircular` | Large streak number centered in a circle |
| `.accessoryCorner` | Streak number in the corner with a label |
| `.accessoryInline` | "🔥 12" as a single text line |

### Data flow

The complication cannot access SwiftData directly in a widget extension with reliability. Write the streak to shared UserDefaults after every log and on every `StreakEngine.calculate` call:

**`WatchViewModel.swift`** — add after `logReps`:

```swift
private func persistStreakForComplication() {
    let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
    defaults.set(loggedStreak, forKey: "currentRepStreak")
    WidgetCenter.shared.reloadAllTimelines()
}
```

Call `persistStreakForComplication()` at the end of `refresh(with:)`.

**iOS `HomeViewModel.swift`** — also write to shared UserDefaults after streak recalculation so the complication stays current even when logging on iPhone:

```swift
UserDefaults(suiteName: "group.com.rylanddean.justreps")?
    .set(loggedStreak, forKey: "currentRepStreak")
```

### `JustRepsComplication.swift` (new file in widget target)

```swift
import WidgetKit
import SwiftUI

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct JustRepsComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: .now, streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: .now, streak: currentStreak()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let entry = ComplicationEntry(date: .now, streak: currentStreak())
        completion(Timeline(entries: [entry], policy: .atEnd))
    }

    private func currentStreak() -> Int {
        UserDefaults(suiteName: "group.com.rylanddean.justreps")?
            .integer(forKey: "currentRepStreak") ?? 0
    }
}

struct JustRepsComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.streak)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(entry.streak > 0 ? Color(red: 95/255, green: 211/255, blue: 141/255) : .secondary)
                    Text("DAYS")
                        .font(.system(size: 7, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        case .accessoryCorner:
            Text("\(entry.streak)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .widgetLabel("REP STREAK")
        case .accessoryInline:
            Text(entry.streak > 0 ? "🔥 \(entry.streak)" : "Log reps")
        default:
            Text("\(entry.streak)")
        }
    }
}

@main
struct JustRepsComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "JustRepsStreak", provider: JustRepsComplicationProvider()) { entry in
            JustRepsComplicationView(entry: entry)
        }
        .configurationDisplayName("Rep Streak")
        .description("Your current Just Reps streak.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}
```

### App Group entitlement

The widget extension target also needs `group.com.rylanddean.justreps` in its entitlements. Add via Xcode → Widget target → Signing & Capabilities → App Groups.

## Files

- New target: `Just Reps Watch Widget`
- New file: `Just Reps Watch Widget/JustRepsComplication.swift`
- New file: `Just Reps Watch Widget/Just_Reps_Watch_Widget.entitlements`
- `Just Reps Apple Watch Watch App/WatchViewModel.swift` — add `persistStreakForComplication()`
- `Just Reps/ViewModels/HomeViewModel.swift` — write streak to shared UserDefaults

## Acceptance

- Complication appears in the watch face picker under "Just Reps"
- `.accessoryCircular` shows the streak number in `successGreen` when > 0
- Complication updates within seconds of logging reps on either device
- Shows neutral state (greyed out) when streak is 0
- Does not require the app to be open to display current streak
