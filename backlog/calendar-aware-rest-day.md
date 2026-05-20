# Calendar-Aware Rest Day

> The app notices before you have to.

---

## Summary

With user permission, Just Reps checks the user's calendar (via EventKit) for days that are unusually dense — back-to-back events, travel days, all-day blocks — and quietly surfaces a rest day suggestion card the evening before. One tap to schedule the rest day. One tap to dismiss. The app never makes the decision for the user; it just surfaces the option at a useful moment.

---

## Why it fits the brand

Just Reps doesn't coach. It doesn't prescribe. But it can notice. A user who has a 6AM flight tomorrow might forget they can take a rest day without breaking their streak. The card is not advice — it's an observation with a convenient shortcut. The distinction matters: "Tomorrow looks packed" is a mirror, not a directive. The user chooses what to do with it.

This is the only time Just Reps reaches outside its own data, and it does so only with explicit, revocable permission. The calendar data stays on-device. EventKit never sends it anywhere.

---

## User story

> As a frequent traveller, I want the app to notice when I have a brutal travel day coming and offer to set a rest day — so I don't have to remember to do it myself the night before.

---

## Apple Intelligence connection

This feature uses **Siri's personal context** concept but implemented via `EventKit` rather than `INIntentDomains` — calendar data is directly accessible via EventKit without requiring Apple Intelligence. However, Apple Intelligence (iOS 18.2+) enhances this by making the EventKit data available to Siri for conversational prompts:

- "Hey Siri, should I take a rest day tomorrow?" → Siri reads the calendar, sees back-to-back events, responds: "Tomorrow looks packed. Want me to set a rest day in Just Reps?"
- This uses `AppIntent` + Siri's awareness of calendar context — no custom ML required.

The EventKit-only path (no Apple Intelligence) is the V1. The Siri conversational path is V2.

---

## Design

### V1: In-app suggestion card

**Trigger:** Each evening at 7PM (local), `NotificationManager` checks the next calendar day for event density. If `calendarEventHours(for: tomorrow) ≥ 8` (8 or more hours of events), a suggestion card is queued.

**Card:**

```
┌─────────────────────────────────────┐
│  Tomorrow looks packed.             │
│  Rest day?                          │
│                          [ Yes ]    │
└─────────────────────────────────────┘
```

- **Position:** Top of `HomeView`, above the streak header. Only appears once per triggering day.
- **"Yes":** Schedules a rest day for tomorrow (same mechanism as the Rest Day feature). Card dismisses.
- **Dismiss (tap outside or swipe down):** Card dismissed for that day. No follow-up.
- **No notification.** The card appears on next app open after 7PM. If the user doesn't open the app, they never see it.

### V2: Siri conversational trigger

```
User: "Hey Siri, should I take a rest day tomorrow?"
Siri: "Tomorrow has 9 hours of events. Want me to set a rest day in Just Reps?"
User: "Yes."
Siri: "Done. Rest day set for tomorrow."
```

Uses `SetRestDayIntent` (a new AppIntent wrapping the existing rest day mechanism) + Siri's calendar awareness to answer the context question.

---

## Permission model

**First trigger:** Before the card can ever appear, Just Reps must request `EventKit` calendar read permission. This is requested in Settings → "Calendar" (a new row), not on first launch.

- Settings row: "Calendar Access"
- Sub-label: "Suggest rest days when tomorrow is packed."
- Tapping triggers `EKEventStore.requestFullAccessToEvents()` (iOS 17+)
- If denied: the row shows "Enable in Settings → Privacy → Calendars → Just Reps." The feature is simply off.

**No calendar data is stored.** The check is performed in-memory each evening. EventKit data is never written to UserDefaults or SwiftData.

---

## "Packed day" definition

```swift
func isPackedDay(_ date: Date, store: EKEventStore) -> Bool {
    let events = store.events(matching: store.predicateForEvents(
        withStart: date.startOfDay,
        end: date.endOfDay,
        calendars: nil
    ))
    let totalHours = events
        .filter { !$0.isAllDay }
        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600 }
    let hasAllDay = events.contains { $0.isAllDay }

    return totalHours >= 8 || hasAllDay
}
```

All-day events (travel, vacation, "Out of office") automatically qualify. Timed events totalling 8+ hours qualify. The threshold is not configurable.

---

## Acceptance criteria

- [ ] Settings → "Calendar Access" row triggers EventKit permission request
- [ ] If permission denied: feature is off, row shows path to Settings
- [ ] Evening check runs at 7PM; if tomorrow is "packed," suggestion card is queued
- [ ] Card appears at top of `HomeView` on next open after 7PM trigger
- [ ] "Yes" schedules a rest day for tomorrow via existing rest day mechanism
- [ ] Dismissing the card suppresses it for that calendar day
- [ ] Card never appears if rest day is already set for tomorrow
- [ ] Card never appears if the Streak Freeze is active
- [ ] No calendar data written to UserDefaults or SwiftData
- [ ] (V2) `SetRestDayIntent` responds to Siri's calendar-context question

---

## What this is NOT

- Not a coach or a directive — always offers, never decides
- Not a notification — the card surfaces on next app open only
- Not automatic — requires explicit calendar permission grant in Settings
- Not an analysis of event content — only checks hours and all-day flags, never reads event titles
- Not triggered by the user's own recurring events like "Workout" (those are scheduled, not packed-day signals)
