# Watch: Cut tabs from 6 to 3

**Status:** Ready  
**Effort:** S  
**Risk:** Low

## Problem

The Watch app has 6 page-style tabs. Three of them (Training Load, Goal Suggestions, Milestones) require significant setup, are rarely useful at a glance, or duplicate data already visible on the Streak tab. On a watch, 6 swipes to explore violates the brand principle: if a first-time user can't understand it in 3 seconds, reconsider it.

Additionally, `WatchTrainingLoadView` shows "Open iPhone app to sync." when HealthKit data isn't available — a dead-end screen on the user's wrist.

## Change

### `ContentView.swift`

Remove tabs 3–5 (Training Load, Goal Suggestions, Milestones):

```swift
// Before — 6 tabs
TabView {
    WatchHomeView(vm: vm, context: context).tag(0)
    WatchStreakView(vm: vm).tag(1)
    WatchActivityView(vm: vm).tag(2)
    WatchTrainingLoadView(vm: vm).tag(3)
    WatchGoalSuggestionsView(vm: vm).tag(4)
    WatchMilestonesView(vm: vm).tag(5)
}

// After — 3 tabs
TabView {
    WatchHomeView(vm: vm, context: context).tag(0)
    WatchStreakView(vm: vm).tag(1)
    WatchActivityView(vm: vm).tag(2)
}
```

### `WatchViewModel.swift`

Remove dead properties and methods no longer needed by any view:

- `trainingLoadTodayMins`, `trainingLoadWeeklyMins`, `trainingLoadTrend`, `hasTrainingLoadData`
- `goalRecommendations`, `applyGoalRecommendation(_:)`, `roundToNearest5(_:)`
- `milestoneThresholds`, `nextMilestone(for:)`
- `WatchGoalRec` struct

Remove the training load reads from `loadPreferences()`:

```swift
// Remove these three lines
trainingLoadTodayMins = defaults.integer(forKey: "trainingLoadTodayMins")
trainingLoadWeeklyMins = defaults.integer(forKey: "trainingLoadWeeklyMins")
trainingLoadTrend = defaults.string(forKey: "trainingLoadTrend") ?? "neutral"
hasTrainingLoadData = defaults.object(forKey: "trainingLoadTodayMins") != nil
```

### Delete files

- `WatchTrainingLoadView.swift`
- `WatchGoalSuggestionsView.swift`
- `WatchMilestonesView.swift`

## Files

- `Just Reps Apple Watch Watch App/ContentView.swift`
- `Just Reps Apple Watch Watch App/WatchViewModel.swift`
- `Just Reps Apple Watch Watch App/WatchTrainingLoadView.swift` — delete
- `Just Reps Apple Watch Watch App/WatchGoalSuggestionsView.swift` — delete
- `Just Reps Apple Watch Watch App/WatchMilestonesView.swift` — delete

## Acceptance

- Watch app opens to the log screen with no visible indicator of additional complexity
- Swiping left twice reaches the 7-day activity chart; no further tabs exist
- Build compiles with no unused-variable warnings from removed ViewModel properties
