# Anchor Reminders

> The reminder that meets you where you already are.

---

## Summary

Instead of picking an arbitrary clock time, the user writes a short daily anchor — "after my morning coffee," "when I get home," "after my shower" — and the notification copy echoes it back. The notification still fires at a user-set time, but the copy creates a habit-stacking association between the existing moment and the act of logging. The habit doesn't need to be built from scratch; it attaches to one that already exists.

This is a separate, proactive notification distinct from the at-risk reminder. It fires when the user plans to log, not after they've failed to.

---

## Why it fits the brand

Trigger-based habit stacking is one of the most evidence-backed techniques in behavioural science. Every fitness app sends a clock-time notification; none send one that sounds like it knows your day. The anchor is the user's own words, written once, forgotten, and then heard back at the right moment. The app doesn't coach — it just echoes.

This is the quietest possible intervention to help the habit stick.

---

## User story

> As someone who always means to log right after my morning coffee but forgets once work starts, I want my reminder to say "Coffee's done. Time to log." — so the habit is tethered to something real, not a number on a clock.

---

## Design

### Settings

- **Location:** Settings → Notifications → a new optional row below the time picker
- **Label:** `"Daily anchor"`
- **Sub-label:** `"A moment to pair with your logging habit."`
- **Input:** Plain text field, 35-character max
- **Placeholder:** `"e.g. after my morning coffee"`
- **No suggestions from the app.** The words are the user's own. No chips, no presets.
- **Clear button:** An `×` to remove the anchor and return to the default notification copy.

### Notification copy

| State | Title | Body |
|-------|-------|------|
| No anchor set | `Just Reps` | *(empty — the reminder is time-only)* |
| Anchor set | `Just Reps` | `"[Anchor]. Time to log."` |

**Examples:**
- `"After my morning coffee. Time to log."`
- `"When I get home. Time to log."`
- `"Shoes off. Time to log."`

The anchor text appears verbatim. No capitalisation correction. No punctuation editing. If the user writes "coffee's ready", that's what fires.

### Timing

- This is an **opt-in proactive reminder**, separate from the at-risk notification.
- It fires at the user's set notification time (the same time picker already in Settings).
- If the user has not logged by `preferredLogHour + 3`, the at-risk notification still fires independently (see `smart-reminder-timing.md`).
- **Maximum two notifications per day total** — one anchor reminder (proactive) and one at-risk reminder (reactive). If the user logs before the at-risk window, the at-risk notification is cancelled.

### Notification scheduling

```swift
// In NotificationManager
func scheduleAnchorReminder(at time: DateComponents, anchor: String?) {
    let content = UNMutableNotificationContent()
    content.title = "Just Reps"
    if let anchor, !anchor.isEmpty {
        content.body = "\(anchor). Time to log."
    }
    // body empty if no anchor — notification is still sent (time-only nudge)
    content.sound = .none
    let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
    let request = UNNotificationRequest(
        identifier: "anchor-reminder",
        content: content,
        trigger: trigger
    )
    UNUserNotificationCenter.current().add(request)
}
```

---

## Acceptance criteria

- [ ] Settings → Notifications shows an "Daily anchor" text field below the time picker
- [ ] Field has a 35-character limit; no suggestions or presets from the app
- [ ] When an anchor is set, notification body reads: `"[anchor text]. Time to log."`
- [ ] When no anchor is set, notification is delivered with empty body (time-only)
- [ ] Anchor text is stored in UserDefaults and persists across app launches
- [ ] An `×` button clears the anchor field and resets notification to default
- [ ] At-risk notification still fires independently if reps are not logged by the smart window
- [ ] Maximum one anchor reminder and one at-risk reminder per day

---

## What this is NOT

- Not a second at-risk notification — it fires proactively, before the streak is at risk
- Not suggested or pre-filled by the app — the words are entirely the user's
- Not a smart assistant — no NLP, no interpretation, no reformatting of the anchor text
- Not required — the proactive reminder is opt-in; the at-risk reminder remains the default
- Not a habit tracker — the anchor is not logged, analysed, or reported anywhere
