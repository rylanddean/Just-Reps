# Personal Best Whisper

> A quiet acknowledgment of something real.

---

## Summary

When the total reps logged today for an exercise surpass that exercise's all-time single-day record, the rep count in the exercise card briefly pulses `successGreen` — one soft beat, ~0.4 seconds — then returns to its normal colour. No banner appears. No badge is stored. Nothing is logged beyond the `WorkoutEntry` that already exists. The moment happens once and is gone.

---

## Why it fits the brand

The brand celebrates consistency, not performance. But occasionally a user does something genuinely impressive — and the app staying completely silent feels like it missed something real. The Personal Best Whisper resolves this tension: it acknowledges the moment without making a production of it. The delight is private, proportional, and gone before it becomes noise.

This is the opposite of most fitness apps, which treat every milestone as a content opportunity. Here, the milestone flickers and disappears. Only the user who was paying attention even saw it.

---

## User story

> As someone who just hit 55 push-ups in a single day for the first time, I want a quiet signal that the app noticed — not a badge or a banner, just something — so the moment feels acknowledged without the app interrupting my day.

---

## Design

### Detection

On every rep-log action, `HomeViewModel` computes whether today's total for that exercise has crossed the all-time single-day best:

```swift
// In HomeViewModel, after inserting a new WorkoutEntry:
func checkPersonalBest(for exercise: ExerciseType, todayTotal: Int) -> Bool {
    let historicBest = entries
        .filter { $0.exercise == exercise }
        .filter { !Calendar.current.isDateInToday($0.timestamp) }
        .reduce(into: [DateComponents: Int]()) { dict, entry in
            let day = StreakEngine.logicalDay(for: entry.timestamp)
            dict[day, default: 0] += entry.reps
        }
        .values
        .max() ?? 0
    return todayTotal > historicBest && historicBest > 0
}
```

- **`historicBest > 0`** — the whisper only fires if there is prior history to beat. A brand-new exercise cannot have a personal best on day one.
- **`!isDateInToday`** — today's own entries are excluded from the baseline to prevent the pulse firing on every rep after a low-history launch.

### Animation

```swift
// In ExerciseCard, bound to a @State var personalBestPulse: Bool
.foregroundStyle(personalBestPulse ? AppTheme.Colors.successGreen : Color(UIColor.label))
.animation(.easeOut(duration: 0.4), value: personalBestPulse)

// Triggered from HomeViewModel via a published signal:
withAnimation {
    personalBestPulse = true
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
    personalBestPulse = false
}
```

- **Duration:** 0.4s ease-out. Fast enough to feel like a flicker; slow enough to register.
- **Element:** The rep count text only — not the card background, not the progress bar.
- **Haptic:** `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` — one beat, coinciding with the colour shift.
- **No second pulse.** Once the threshold is crossed, logging additional reps that day does not re-trigger it.

### State management

```swift
// In HomeViewModel
var personalBestTriggered: Set<ExerciseType> = []  // reset at 3AM logical day boundary

// Prevents re-firing within the same day:
if !personalBestTriggered.contains(exercise), checkPersonalBest(for: exercise, todayTotal: total) {
    personalBestTriggered.insert(exercise)
    triggerPersonalBestWhisper(for: exercise)
}
```

### Relationship to Ghost Streak

`ghost-streak.md` shows the previous best streak as a faint secondary number when the current streak is behind it. Personal Best Whisper is complementary but orthogonal: it responds to a single-day rep total milestone, not a streak length milestone. Neither references the other in the UI.

---

## Acceptance criteria

- [ ] `checkPersonalBest` correctly computes all-time single-day best excluding today's entries
- [ ] Whisper only fires when `todayTotal > historicBest && historicBest > 0`
- [ ] Rep count text pulses `successGreen` for ~0.4s then returns to normal label colour
- [ ] `UIImpactFeedbackGenerator(style: .medium)` fires once on trigger
- [ ] Whisper fires at most once per exercise per logical day
- [ ] No banner, badge, sheet, or persistent record is created
- [ ] `personalBestTriggered` resets at the 3AM logical day boundary
- [ ] No animation fires for exercises with no prior history (first logged day)
- [ ] Whisper fires correctly when multiple exercises hit personal bests on the same day (one pulse per exercise, not batched)

---

## What this is NOT

- Not stored — there is no "personal records" screen, no history of whispers
- Not labelled — no "New PB!" text appears anywhere
- Not a notification — the whisper happens only during active in-app logging
- Not social — the share card does not reference personal bests
- Not volume-sensitive — it doesn't matter whether the user beat their best by 1 rep or 100
- Not shown for goal completion — that already has `successGreen` progress bar fill; this is for all-time daily rep bests only
