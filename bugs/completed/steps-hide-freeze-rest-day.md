# Steps Hide Freeze / Rest Day

**Severity:** Medium — routine users with Walking configured silently lose access to rest days and freeze prompts

## Problem

Walking steps are stored as `.workout` kind `WorkoutEntry` records. Both `canMarkRestDay` and the condition gating the freeze prompt check for the absence of workout entries today. As a result, any user with Walking active who has synced steps — even just a few thousand steps on a normal morning — finds the rest day option and streak freeze unavailable, even though they haven't done a deliberate workout.

## Root Cause

`HomeViewModel.canMarkRestDay` (line ~172):

```swift
guard todaysEntries.filter({ $0.kind == .workout }).isEmpty else { return false }
```

`HomeViewModel.updateWalkingStepsIfNeeded` inserts walking steps as:

```swift
context.insert(WorkoutEntry(exercise: .walking, reps: steps))
```

This is a `.workout` kind entry, so `canMarkRestDay` returns `false` as soon as any steps are synced.

The freeze prompt (`shouldShowFreezePrompt`) checks whether *yesterday* had entries, so it isn't directly affected by today's steps — but `dayState` is also affected: any walking entry pushes `dayState` from `.fresh` to `.alive`, which hides the freeze UI in views that condition on the day being fresh.

## Steps to Reproduce

1. Add Walking to active exercises
2. Walk a few hundred steps (or let HealthKit sync overnight)
3. Open Just Reps on a day you haven't worked out
4. Observe: rest day option is hidden; day shows as `.alive` instead of `.fresh`

## Expected Behavior

Walking steps should not count as a "workout entry" for the purpose of showing freeze / rest day options. A user who walked to the coffee shop hasn't worked out and should still be able to mark a rest day or use a freeze token.

## Fix

In `canMarkRestDay`, exclude walking entries from the workout check:

```swift
guard todaysEntries.filter({ $0.kind == .workout && $0.exercise != .walking }).isEmpty else { return false }
```

Apply the same exclusion anywhere else that gates UI on "no workout entries today" but should mean "no deliberate workout today."

Also audit `dayState`: decide whether walking steps alone should push the day to `.alive` — the current brand position is that showing up means doing your exercises, not background step counting.

## Acceptance Criteria

- [ ] `canMarkRestDay` returns `true` when only walking step entries exist today (no deliberate workout entries)
- [ ] Rest day card appears on Home when the only today entries are walking steps
- [ ] Freeze prompt / `shouldShowFreezePrompt` is not suppressed by walking step entries
- [ ] `dayState` remains `.fresh` when the only today entries are walking steps (no deliberate sets logged)
- [ ] Deliberate reps (non-walking) still correctly suppress the rest day option and update `dayState`
