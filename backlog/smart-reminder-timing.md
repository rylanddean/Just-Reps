# Smart Reminder Timing

> The nudge arrives when it's actually useful.

---

## Summary

The current at-risk notification fires at a fixed time (after 8PM by default). Smart Reminder Timing passively observes when the user typically logs reps and shifts the at-risk window to match their actual pattern. A user who logs at 6AM every day gets a reminder earlier if they haven't logged by mid-morning — not at 8PM when it's too late to matter. No setup required. No preference to configure. It just learns.

---

## Why it fits the brand

Notifications are opt-in and the app is deliberately non-nagging. But a reminder that fires at the wrong time fails both the user and the brand — it's either irrelevant noise or it arrives after the streak has already been broken. Smart timing makes the one notification Just Reps sends actually useful without increasing notification volume. The learning is invisible: no progress bar, no "I've noticed you log at 6AM" message, nothing. It quietly gets better.

---

## User story

> As someone who usually logs push-ups right after my morning coffee, I want the at-risk reminder to fire if I haven't logged by mid-morning — so it catches me before the day runs away from me, not at 8PM when I'm already in bed.

---

## Design

### Learning algorithm

No ML required. A simple median over the last 14 days of logged entries:

```swift
// Compute preferred log time
static func preferredLogHour(from entries: [WorkoutEntry]) -> Int {
    let recentEntries = entries
        .filter { Calendar.current.isDateInLast14Days($0.timestamp) }
    guard !recentEntries.isEmpty else { return 20 } // default: 8PM

    let hours = recentEntries.map { Calendar.current.component(.hour, from: $0.timestamp) }
    return hours.sorted()[hours.count / 2] // median hour
}
```

### Reminder window

- **At-risk notification fires:** `preferredLogHour + 3` hours (3h grace after typical log time)
- **Floor:** Never before 9AM — even morning loggers get a mid-morning nudge, not a 5AM alarm
- **Ceiling:** Never after 9PM — the existing behaviour for night-owls
- **Minimum data:** Requires at least 7 logged days in the last 14 before shifting from default 8PM

### Recalculation

- Recalculated each day when `NotificationManager` schedules the next at-risk notification
- Calculated from `WorkoutEntry` timestamps — no new data storage required
- The computed hour is not exposed to the user anywhere in the UI

### Notification copy

Unchanged: `"Your streak is at risk. Still time."` — the timing changes, the message doesn't.

### Settings interaction

- If the user has manually set a notification time in Settings, that setting takes precedence over smart timing. Smart timing is the fallback when no explicit time is set.
- A new sub-label under the notification time picker in Settings: `"Or learn from your habits — remove the custom time."` This is optional copy; discuss with design before shipping.

---

## Acceptance criteria

- [ ] `preferredLogHour` computed from median logged hour over last 14 days
- [ ] Requires ≥7 logged days in the 14-day window before deviating from 8PM default
- [ ] At-risk notification fires at `preferredLogHour + 3h`, floored at 9AM, capped at 9PM
- [ ] Recalculated daily when the notification is scheduled
- [ ] If user has a manually set reminder time in Settings, smart timing is not applied
- [ ] No UI exposed for the learned time — fully invisible to the user
- [ ] Notification copy is unchanged

---

## What this is NOT

- Not a machine learning model — median of 14 days, nothing more
- Not configurable — the user doesn't set the window, the pattern sets it
- Not shown to the user — no "I noticed you log at 6AM" messaging
- Not a second notification — still exactly one at-risk notification per day maximum
- Not a replacement for the notification opt-in flow
