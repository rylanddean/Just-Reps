# Feature: Exercise card done state

**Status:** Ready  
**Effort:** M  
**Risk:** Low — purely visual/animation change

## Problem

When a daily goal is met, the exercise card stays fully expanded — all increment buttons visible, only the rep count turns green. There is no visual completion signal beyond the number color. The home screen looks identical before and after finishing all goals, except for a brief banner overlay that auto-dismisses.

This misses the core brand moment: showing up and completing a goal should feel satisfying, not invisible.

## Change

When `current >= goal`, the exercise card transitions to a compact done state:

### Done state layout

```
💪  Pushups                    ✓  30 reps
```

Single row: emoji + name on the left, checkmark + rep count on the right. The progress bar and all increment buttons are hidden. A small `+` icon on the trailing edge (or long press) allows adding more reps if the user wants to keep going — it expands the card back inline.

### Behaviour

- Transition is animated: increment buttons fade out, progress bar shrinks, layout collapses. Use `.animation(.spring(response: 0.4, dampingFraction: 0.85), value: isComplete)`.
- Medium haptic fires on transition (already fires on goal hit — keep it).
- Done state is green text for the rep count (`successGreen`).
- Tapping anywhere on a done card (or a dedicated `+` button) re-expands it. No confirmation needed.
- If user adds more reps after goal is met, card stays expanded until manually collapsed or app is relaunched.

### Implementation

Add `@State private var isExpanded = true` to `ExerciseCard`. Set `isExpanded = false` when `isComplete` becomes true for the first time (via `.onChange(of: isComplete)`). `isExpanded = true` when the user taps to re-expand.

The `body` branches on `isComplete && !isExpanded`:

```swift
if isComplete && !isExpanded {
    doneRow
} else {
    fullCard
}
```

`doneRow` and `fullCard` share the same outer padding and background clip shape so the card height changes smoothly.

## Files

- `Just Reps/Components/ExerciseCard.swift`

## Acceptance

- Goal met → card collapses to single done row with animation
- Haptic fires on collapse
- Done row shows emoji, name, checkmark, rep count in green
- Tapping done row re-expands card with increment buttons visible
- 0-rep state and in-progress state look identical to current
- All exercises done → home screen is a compact list of green done rows
