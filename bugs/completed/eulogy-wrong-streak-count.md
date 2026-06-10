# Streak Broken Popup Shows Wrong Count

**Severity:** High — the eulogy sheet is the primary "streak broken" moment; showing the wrong number is confusing and erodes trust

## Problem

When a streak is broken, `StreakEulogySheet` displays a length that doesn't match the streak the user actually experienced. In the reported case: the user broke a 1-day (MVR-aware) streak, but the popup said "7 days."

## Root Cause

`HomeViewModel.checkEulogy()` calls `StreakEngine.lastCompletedStreak(entries:)`, which computes streak length using the basic "any entries" path — it counts every day that has *any* `WorkoutEntry`, regardless of MVR thresholds:

```swift
// StreakEngine.lastCompletedStreak
let completedDays = Set(entries.map { logicalDay(for: $0.timestamp) })
```

Meanwhile, `loggedStreak` (the number shown in the streak counter) uses the MVR-aware `StreakEngine.calculate(entries:activeExercises:goals:minimumViableReps:effectiveFrom:)` path. The two diverge the moment an MVR is configured and not consistently met.

The user logged reps on 7 days in a row but only met their MVR on 1 of those days. `loggedStreak` correctly showed 1; `lastCompletedStreak` returned 7 because it found 7 days with any entries at all.

## Fix

`StreakEngine.lastCompletedStreak` needs to accept the same MVR parameters as the main `calculate` method and work from the same `qualifiedDays` set. Alternatively, `checkEulogy` can compute the last streak length directly from the MVR-aware qualified days rather than calling `lastCompletedStreak`.

Minimal approach — add an overload of `lastCompletedStreak` that accepts qualified days:

```swift
static func lastCompletedStreak(
    qualifiedDays: Set<DateComponents>
) -> (length: Int, endDay: DateComponents)? { ... }
```

Then `checkEulogy` passes the same `qualifiedDays` that `loggedStreak` is derived from, so both the counter and the popup agree.

## Acceptance Criteria

- [ ] `StreakEulogySheet` displays the same streak length that was shown in the streak counter before the streak broke
- [ ] Eulogy only fires when the MVR-aware streak (not the raw entry-count streak) has dropped to 0
- [ ] Eulogy threshold (currently ≥ 7 days) is evaluated against the MVR-aware length, not the raw entry count
- [ ] Users without any MVR configured see no change in behaviour (the two paths agree when MVR is unset)
