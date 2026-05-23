# Just Show Up Mode

> The reps can wait. The habit can't.

---

## Summary

An opt-in mode that strips the home screen of all rep counts, progress bars, goals, and pill buttons. Each exercise card becomes a single large tap target — a name and a gentle binary state: shown up, or not yet. The streak continues if every exercise is marked. Nothing is counted. Nothing is tracked beyond the fact of showing up.

For users going through injury, grief, burnout, travel, illness, or any season where the numbers feel impossible but the habit still matters.

---

## Why it fits the brand

The brand's core thesis is: showing up matters more than how many. Ease Mode lowers the bar. Just Show Up Mode removes the bar entirely. It's the purest expression of what Just Reps is for — not a performance tracker, not a goal machine, just a witness to the fact that you're still here, still doing something, still in the habit.

No competitor has a mode that deliberately discards its own core metric. That restraint is exactly what separates Just Reps.

---

## User story

> As someone recovering from a wrist injury, I can't do my usual push-up count — but I can still move. I want the app to just ask "did you show up?" and leave the counting out of it so I don't feel like I'm failing every day.

---

## Design

### Activation

- **Location:** Settings → a clearly labelled row: `"Just Show Up Mode"`. Sub-label: `"Log without counting. Streak continues."`
- **Toggle:** Standard SwiftUI `Toggle`. Off by default.
- **No confirmation sheet.** Turning it on is not destructive. The mode can be reversed instantly.
- **On disable:** Goals, counts, and progress bars return immediately. Historical entries created during Just Show Up Mode retain their rep value (see data model below).

### Home screen — while active

Each exercise card is simplified:

```
┌───────────────────────────────────┐
│  💪  Push-ups                     │
│                                   │
│  ┌─────────────────────────────┐  │
│  │        Showed up            │  │  ← large tappable pill, full card width
│  └─────────────────────────────┘  │
└───────────────────────────────────┘
```

**Before tap:**
- Pill label: `"Show up"` in secondary colour
- No rep count displayed anywhere
- No progress bar
- No +5 / +10 / +25 buttons

**After tap:**
- Pill background fills to `successGreen`
- Pill label: `"Showed up"`
- Soft haptic: `UIImpactFeedbackGenerator(style: .soft)`
- No rep count appears — the visual state is the only feedback

**Tapping again (undo):**
- Pill reverts to unfilled state
- Haptic: `UINotificationFeedbackGenerator().notificationOccurred(.warning)`
- Entry is removed from SwiftData for today

### Streak logic

- Streak counts the day as logged if every active exercise has been tapped
- The underlying entry is a `WorkoutEntry` with `reps: 1` (a valid, non-zero entry sufficient to mark the day)
- `StreakEngine` is unchanged — it sees a normal entry and counts the day

### Data model

```swift
// WorkoutEntry logged in Just Show Up Mode
WorkoutEntry(
    timestamp: .now,
    exercise: exercise,
    reps: 1           // minimum valid value; not displayed anywhere in this mode
)
// The entry is indistinguishable in SwiftData from a normal entry.
// History view shows "1 rep" for these entries — acceptable, accurate, honest.
```

### Other UI surfaces while active

| Surface | Behaviour |
|---------|-----------|
| Streak header | Unchanged — streak count still displays |
| History view | Shows entries as `"1 rep"` — no special label or indicator |
| Heatmap | Day marked as logged normally |
| Notifications | Copy unchanged |
| Settings → Ease Mode | Can coexist (both active simultaneously is allowed; neither conflicts) |

### Indicator that mode is active

- Settings toggle is on — the only indicator
- No home screen banner, no persistent badge, no colour change to the streak header
- If a user is confused about why counts are missing, they look in Settings (as with any setting)

---

## Acceptance criteria

- [ ] Settings shows a "Just Show Up Mode" toggle, off by default
- [ ] When active, each exercise card shows only name, emoji, and a single "Show up" pill
- [ ] No rep counts, no progress bars, and no +5/+10/+25 buttons appear
- [ ] Tapping the pill creates a `WorkoutEntry` with `reps: 1`; pill fills to `successGreen`
- [ ] Tapping a filled pill undoes the entry; pill reverts to unfilled state
- [ ] Streak counts the day as logged if all exercises are tapped
- [ ] `StreakEngine` requires no changes — it processes `reps: 1` entries normally
- [ ] History view shows `"1 rep"` for entries created in this mode — no special treatment
- [ ] Disabling the mode immediately restores the standard card UI
- [ ] Ease Mode and Just Show Up Mode can be active simultaneously without conflict

---

## What this is NOT

- Not a rest day — the user still marks every exercise; the day is not skipped
- Not Ease Mode — Ease Mode halves numerical goals; this mode removes numbers entirely
- Not invisible in History — entries still appear; they just show 1 rep
- Not a separate onboarding state — existing users activate it voluntarily from Settings
- Not a judgment — the app doesn't ask why, suggest a return date, or celebrate the return to normal mode
- Not for new users — there's no suggestion to use this during onboarding
