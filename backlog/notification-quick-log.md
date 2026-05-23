# Notification Quick Log

> Log without opening the app.

---

## Summary

Long-pressing the daily at-risk notification reveals inline action buttons — one per active exercise — that log a default rep increment directly from the notification drawer. The app never needs to open. The rep is recorded, the widget refreshes, the streak is protected. For the moments when opening the app adds just enough friction to make skipping feel easier.

---

## Why it fits the brand

One-tap logging is the core promise. The app should disappear as much as possible from the user's day. Notification Quick Log extends that promise to the OS level: the notification that warns you also fixes the problem. One interaction, done, move on.

The lock screen widget (see `lock-screen-widget.md`) is intentionally read-only — iOS does not allow widgets to trigger writes. Notification actions have no such restriction, making them the correct mechanism for OS-level logging.

---

## User story

> As someone who gets the at-risk notification while cooking dinner, I want to tap "+10 push-ups" right from the notification and not have to wash my hands, dry them, unlock my phone, find the app, and log — so I actually do it instead of telling myself I'll do it later.

---

## Design

### Notification category

A `UNNotificationCategory` is registered with one action per active exercise at the time the notification is scheduled. Because notification actions are registered at the category level (not per-notification), the category is rebuilt each time active exercises change.

```swift
// NotificationManager
func registerQuickLogCategory(for exercises: [ExerciseType]) {
    let actions = exercises.map { exercise in
        UNNotificationAction(
            identifier: "log-\(exercise.rawValue)",
            title: "+\(quickLogAmount) \(exercise.displayName)",
            options: []   // background delivery — no app launch
        )
    }
    let category = UNNotificationCategory(
        identifier: "AT_RISK_QUICK_LOG",
        actions: actions,
        intentIdentifiers: [],
        options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
}
```

### Quick log amount

- Fixed at **+10 reps** per action tap — not configurable.
- The goal is to make logging fast and friction-free. Presenting a rep picker defeats the purpose.
- Users who want a different amount can open the app and use pill buttons normally.

### Background delivery

- Actions use `UNNotificationAction` with no `.foreground` option — the app is not launched.
- The action is handled in `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)`.
- The handler creates a `WorkoutEntry` in SwiftData and calls `WidgetCenter.shared.reloadAllTimelines()`.

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
) async {
    guard response.actionIdentifier.hasPrefix("log-") else { return }
    let exerciseRaw = String(response.actionIdentifier.dropFirst(4))
    guard let exercise = ExerciseType(rawValue: exerciseRaw) else { return }
    let entry = WorkoutEntry(timestamp: .now, exercise: exercise, reps: quickLogAmount)
    // Insert into modelContext — requires background actor-safe access
    await MainActor.run {
        modelContext.insert(entry)
        try? modelContext.save()
    }
    WidgetCenter.shared.reloadAllTimelines()
}
```

### Notification appearance (long-pressed)

```
┌─────────────────────────────────┐
│  Just Reps                      │
│  Your streak is at risk.        │
│  Still time.                    │
│                                 │
│  [ +10 Push-ups ]               │
│  [ +10 Squats   ]               │
│  [ +10 Pull-ups ]               │
└─────────────────────────────────┘
```

- Actions appear in the order exercises appear on the home screen
- Maximum 4 actions (iOS displays up to 4 notification actions)
- If more than 4 exercises are active, show the first 4 by home screen order

### Widget and home screen update

- After a quick log action, `WidgetCenter.shared.reloadAllTimelines()` ensures the home screen widget and lock screen widget update within ~60 seconds
- The home screen rep count updates on next app open via `@Query` — no special handling needed

### After logging via notification

- If all goals are met via quick log, the at-risk notification for that day is cancelled
- The app checks goal completion in the notification handler and calls `UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:)` if appropriate

---

## Acceptance criteria

- [ ] `AT_RISK_QUICK_LOG` category registered on app launch and whenever active exercises change
- [ ] At-risk notification includes one action per active exercise (max 4), labelled `"+10 [Exercise]"`
- [ ] Tapping an action creates a `WorkoutEntry` with `reps: 10` without opening the app
- [ ] Widget timelines reload within 60 seconds of a quick log action
- [ ] If all goals are met after a quick log, pending at-risk notification is cancelled
- [ ] Quick log entries appear in History view and contribute to heatmap normally
- [ ] Actions work in background (no foreground launch option)
- [ ] If the user has 0 active exercises, no actions appear (category has empty actions array)
- [ ] Quick log respects Just Show Up Mode: if active, action logs `reps: 1` and marks the exercise tapped

---

## What this is NOT

- Not a replacement for in-app logging — it's a fallback for the notification moment only
- Not configurable per-exercise (all actions log +10; complex configuration defeats the speed goal)
- Not a widget interaction — lock screen widgets are read-only by iOS design
- Not triggered by any notification other than the at-risk notification
- Not shown for the anchor reminder (proactive) — only for the at-risk notification
