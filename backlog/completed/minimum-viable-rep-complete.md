# Minimum Viable Rep

> Even 5 reps counts.

---

## Summary

A second, lower threshold per exercise — the floor, not the goal. On a hard day, hitting the MVR keeps the streak alive without requiring a full session. The goal is still the goal; the MVR is just the promise you made to yourself that you won't completely quit.

---

## Why it fits the brand

Just Reps' voice says "even 5 reps counts" — this makes that literal. Every other fitness app celebrates hitting your goal. Just Reps is the only one that celebrates not quitting. MVR formalises the philosophy that showing up at 10% is still showing up.

---

## User story

> As someone with a 50-pushup daily goal who had a brutal day, I want to log 5 reps and know my streak is safe — so I don't feel like I failed and abandon the habit entirely.

---

## Design

- **Set it in Settings**, per exercise. Optional — defaults to off. Label: "Minimum reps to count the day."
- **Streak logic:** If total reps ≥ MVR for all active exercises, the day counts as logged for streak purposes.
- **Home screen:** No visual change to the exercise card. The goal is still shown as the progress target.
- **No badge, no callout** when you only hit the MVR. It logs. That's it.
- **Copy:** Nothing. A day logged is a day logged.

### StreakEngine change

```swift
// New parameter on StreakEngine.calculate
static func calculate(
    entries: [WorkoutEntry],
    goals: [ExerciseType: Int],
    minimumViableReps: [ExerciseType: Int] = [:]  // new
) -> StreakResult
```

A day qualifies if, for each active exercise, either:
- `totalReps >= goal`, or
- `minimumViableReps[exercise] > 0 && totalReps >= minimumViableReps[exercise]`

---

## Acceptance criteria

- [ ] MVR can be set per exercise in Settings (optional, hidden behind "Advanced" or per-exercise row)
- [ ] A day where all exercises hit MVR but not goal counts toward the streak
- [ ] No visual distinction on the home screen between an MVR day and a goal day
- [ ] Goal streak (blue) only ticks if full goal is met — MVR days keep rep streak only
- [ ] MVR persisted to UserDefaults per exercise key

---

## What this is NOT

- Not a "reduced goal" — the goal doesn't change, and the goal streak tracks separately
- Not surfaced on the home screen as a secondary bar or ring
- Not something the app congratulates you on — it just works
