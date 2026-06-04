# Workout Block

> A slot before the day fills up.

---

## Summary

With calendar permission granted, Just Reps scans the user's calendar each morning and drops a 30-minute hold titled "Reps" into the first free slot within their availability window. No notification. No question asked twice. The event just appears — quiet confirmation that time has been protected. If the user has already logged by the time the slot arrives, nothing was wasted. If they haven't, the block kept the moment open.

The user defines when they're generally free to work out — a morning window, an evening window, or both. Just Reps checks the AM window first, then the PM window, placing the block in the earliest available gap it finds.

The app doesn't plan the workout. It doesn't say what to do or how many. It reserves a gap so the intention isn't crowded out by other people's meetings.

---

## Why it fits the brand

The most common reason habits fail isn't lack of motivation — it's lack of a protected moment. This feature doesn't coach. It doesn't program. It doesn't even confirm: it just quietly holds space.

The key distinction: Just Reps' "no plan" principle is about workout *content* — no prescribed sets, no rep targets, no guidance on what to do. This feature plans *time*, not content. The discipline remains the user's. The logistics are Just Reps'.

Every visible output of this feature is outside the app — a calendar entry the user opted into. The home screen doesn't change. Logging is still one tap.

**Brand tension to hold:** This is the furthest Just Reps reaches into daily planning. The boundary is firm: the app creates one blank time block per day, titled "Reps." It never changes the event's content, never analyses the workout, and never surfaces anything inside the app about it. The moment that boundary blurs — suggested workout content in the event notes, an in-app countdown to the block, a banner when the slot arrives — the feature becomes a coach. That's the line.

---

## User story

> As someone whose mornings fill up fast, I want Just Reps to find a free 30 minutes before my day gets packed — so there's a slot reserved for my reps without me having to check the calendar myself.

---

## Apple APIs

**EventKit** is the only framework required. The permission model and `EKEventStore` instance can be shared with Calendar-Aware Rest Day (see `calendar-aware-rest-day.md`). The only addition here is using write access — already granted by `requestFullAccessToEvents()` (iOS 17+).

| API | Purpose |
|-----|---------|
| `EKEventStore.requestFullAccessToEvents()` | Read + write calendar access (iOS 17+) |
| `EKEventStore.predicateForEvents(withStart:end:calendars:)` | Enumerate existing events to find gaps |
| `EKEventStore.defaultCalendarForNewEvents` | Prefill the calendar picker |
| `EKEvent` | Construct the workout block |
| `EKEventStore.save(_:span:commit:)` | Write the event to the chosen calendar |

No EventKitUI required. No server component. All processing is on-device.

---

## Design

### Settings

**Location:** Settings → Notifications → new "Workout block" section, below the reminder rows.

The section contains two rows:

---

**Row 1 — Toggle**

| Property | Value |
|----------|-------|
| Label | `"Block workout time daily"` |
| Sub-label | `"Adds a 30-min hold to your calendar before the day fills up."` |

On first enable, a bottom sheet asks for the calendar only:
- **Calendar** — list of user's writable `EKCalendar` objects; preselected to `EKEventStore.defaultCalendarForNewEvents`
- One "Done" button. No other questions on this screen.

On disable: future event creation stops. Already-created events are not deleted.

---

**Rows 2–3 — Workout availability (Morning / Evening)**

Two named windows, each with its own toggle and From/To time pickers. Both follow the same inline pattern as the existing notification rows — toggle first, then pickers when enabled.

| Window | Toggle label | Default range |
|--------|-------------|---------------|
| Morning | `"Morning"` | 6:00 AM – 12:00 PM |
| Evening | `"Evening"` | 5:00 PM – 9:00 PM |

Both are always visible. At least one must be enabled — disabling the last active window automatically enables the other. The scheduler checks the morning window first; if no gap is found there, it tries the evening window.

No suggestions, no presets. The windows apply to every day of the week; per-day overrides are out of scope for V1.

---

**Stored in UserDefaults:**
- `workoutBlockEnabled: Bool`
- `workoutBlockCalendarID: String`
- `workoutBlockAMEnabled: Bool` (default: `true`)
- `workoutBlockAMStartHour: Int` / `workoutBlockAMStartMin: Int` (default: 6, 0)
- `workoutBlockAMEndHour: Int` / `workoutBlockAMEndMin: Int` (default: 12, 0)
- `workoutBlockPMEnabled: Bool` (default: `false`)
- `workoutBlockPMStartHour: Int` / `workoutBlockPMStartMin: Int` (default: 17, 0)
- `workoutBlockPMEndHour: Int` / `workoutBlockPMEndMin: Int` (default: 21, 0)

### Block creation trigger

**Primary:** On every app foreground (via `scenePhase == .active` in `ContentView`). The `alreadyScheduledToday()` guard ensures the algorithm runs at most once per calendar day. The user sees nothing — it either succeeds silently or doesn't.

**Why app open, not BGAppRefreshTask:** iOS throttles background refresh unpredictably. Since users open Just Reps to log reps, app open guarantees a reliable daily attempt while staying on-device and private.

**Conditions that skip creation:**
- Reps already logged today
- A "Reps" event already exists in the chosen calendar today (prevents duplicates)
- Calendar permission not granted

### Free-slot algorithm

The scheduler iterates the enabled windows in order (AM then PM), returning the first suitable gap it finds.

```swift
// Called for each enabled window
func findFreeSlot(startHour: Int, startMinute: Int,
                  endHour: Int,   endMinute: Int,
                  duration: TimeInterval = 1800) -> Date? {
    let today = Calendar.current.startOfDay(for: .now)
    let windowStart = Calendar.current.date(
        bySettingHour: startHour, minute: startMinute, second: 0, of: today)!
    let windowEnd = Calendar.current.date(
        bySettingHour: endHour, minute: endMinute, second: 0, of: today)!

    // Don't place a block in the past
    let start = max(windowStart, .now)
    guard windowEnd.timeIntervalSince(start) >= duration else { return nil }

    let events = store.events(
        matching: store.predicateForEvents(withStart: start, end: windowEnd, calendars: nil)
    )
    .filter { !$0.isAllDay }
    .sorted { $0.startDate < $1.startDate }

    var cursor = start
    for event in events {
        if event.startDate.timeIntervalSince(cursor) >= duration { return cursor }
        if event.endDate > cursor { cursor = event.endDate }
    }
    return windowEnd.timeIntervalSince(cursor) >= duration ? cursor : nil
}
```

If no gap is found in either window: no event is created, nothing is surfaced to the user.

### Event structure

```swift
let event        = EKEvent(eventStore: store)
event.title      = "Reps"
event.startDate  = foundSlot
event.endDate    = foundSlot.addingTimeInterval(1800)
event.calendar   = chosenCalendar
event.notes      = nil
// No alarm — the block is a space-holder, not a reminder
try store.save(event, span: .thisEvent, commit: true)
```

- Title is `"Reps"` — short, private, unsurprising.
- No alarm. The at-risk notification already handles the reminder role. Two interventions for the same moment is noise.
- No notes. The block is empty by design — the workout content is the user's business.

---

## Permission model

If calendar access was already granted for Calendar-Aware Rest Day, no second prompt is needed — `requestFullAccessToEvents()` covers read and write. If not yet granted, the same flow applies:

- Settings → Calendar Access row triggers `EKEventStore.requestFullAccessToEvents()`
- If denied: "Workout block" toggle is disabled; row shows `"Enable in Settings → Privacy → Calendars → Just Reps."`

---

## Effort / Tier

**Effort:** Medium  
**Tier:** V2  
**Dependency:** Calendar-Aware Rest Day (shares `EKEventStore` and the permission row)

---

## Acceptance criteria

- [ ] Settings → Reminders shows a "Workout block" section with toggle, calendar picker, and morning/evening rows
- [ ] Enabling the toggle requests EventKit access; disables itself if denied
- [ ] Calendar picker is shown when the toggle is on; defaults to `EKEventStore.defaultCalendarForNewEvents`
- [ ] "Morning" toggle defaults to enabled; shows From/To `DatePicker` rows when enabled
- [ ] "Evening" toggle defaults to disabled; shows From/To `DatePicker` rows when enabled
- [ ] Disabling the last active window automatically enables the other
- [ ] Default morning window: 6:00 AM – 12:00 PM; default evening window: 5:00 PM – 9:00 PM
- [ ] All settings are stored in UserDefaults and persist across app launches
- [ ] On app open, if the feature is enabled and no block exists today, the algorithm runs before the home screen renders
- [ ] If a free 30-min slot is found: creates an `EKEvent` titled `"Reps"` with no alarm in the chosen calendar
- [ ] If no free slot is found: no event is created; nothing is surfaced to the user
- [ ] If reps are already logged today: no event is created
- [ ] If a `"Reps"` event already exists today in the chosen calendar: no duplicate is created
- [ ] Disabling the toggle stops future event creation; existing events are not deleted
- [ ] Calendar write permission requested via `EKEventStore.requestFullAccessToEvents()`
- [ ] If permission denied: toggle is disabled; Settings row shows path to Privacy settings
- [ ] No calendar data written to SwiftData; only calendar ID and window prefs in UserDefaults

---

## What this is NOT

- Not a workout program — the event is a blank time hold, not a plan
- Not a notification — no push alert, no badge, no sound
- Not a coaching prompt — event title is `"Reps"`, event notes are empty
- Not an in-app countdown or banner when the slot arrives
- Not automatic on first launch — requires explicit opt-in in Settings
- Not a second reminder — the at-risk notification handles that role; these are separate mechanisms
