# Exercise Archive

> Move on without erasing where you've been.

---

## Summary

When a user stops doing an exercise — injury, boredom, a phase that's over — they currently have no clean exit. Deleting the exercise destroys its history. Leaving it on the home screen clutters the daily view. Archive gives a third path: the exercise leaves the home screen and goal tracking, but its WorkoutEntries stay intact. History and the heatmap keep the full record.

---

## Why it fits the brand

Honest data is core to Just Reps. A user who did 90 days of pull-ups and then stopped shouldn't have to choose between a cluttered home screen and erasing 90 days of history. Archive respects both the present (a clean logging surface) and the past (an accurate record). This is the housekeeping feature every long-term user needs but most apps never build correctly.

---

## User story

> As someone who stopped doing pull-ups after a shoulder issue, I want to remove them from my daily logging view — so my home screen stays clean — without losing the history of the months I did do them.

---

## Design

### Archive action

- **Trigger:** Long-press on an exercise card → context menu → "Archive exercise"
- **Confirmation:** A single `confirmationDialog`: `"Archive [Exercise]? It won't appear on your home screen, but your history stays intact."` Two options: `"Archive"` (destructive style) and `"Cancel"`.
- **No "Delete" option in the same flow.** Archive and delete are separate. Delete remains accessible in Settings → Exercises.

### What changes when archived

| Surface | Behaviour |
|---------|-----------|
| Home screen | Card removed |
| Goal tracking | Excluded from goal streak calculation |
| History view | All past entries still appear, labelled with the exercise name |
| Heatmap | Archived exercise entries still contribute to daily "logged" state |
| Settings → Exercises | Appears in a collapsed "Archived" section at the bottom |

### Reactivating

- In Settings → Exercises, an "Archived" section shows archived exercises.
- Tap any archived exercise → "Reactivate" restores it to the home screen.
- Rep count and goal reset to zero for today; history is unaffected.

### Data model

```swift
// ExerciseType gets an `isArchived: Bool` flag in UserDefaults preferences
// (exercise definitions are not SwiftData models — they're stored as keys)
// WorkoutEntries are unchanged — they reference the exercise by type
```

---

## Acceptance criteria

- [ ] Long-press on an exercise card shows "Archive exercise" in the context menu
- [ ] `confirmationDialog` appears before archiving
- [ ] Archived exercise is removed from `HomeViewModel.activeExercises`
- [ ] Archived exercise entries still appear in `HistoryView`
- [ ] Archived exercise entries still contribute to heatmap day-logged status
- [ ] Archived exercise does NOT count toward goal streak calculation
- [ ] Settings → Exercises shows an "Archived" section with reactivation affordance
- [ ] Reactivating restores the card to the home screen with zero reps today
- [ ] An exercise with no history can still be deleted (not just archived)

---

## What this is NOT

- Not a soft delete — archived exercises are explicitly recoverable
- Not a way to hide past entries from the heatmap
- Not available as a swipe action (long-press only — too destructive for accidental swipe)
- Not automatically suggested by the app ("You haven't logged pull-ups in 30 days — archive?")
