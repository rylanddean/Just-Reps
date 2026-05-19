# Refactor: Goal suggestion inline on ExerciseCard

**Status:** Ready  
**Effort:** S  
**Risk:** Low — view-only change, no model changes

## Problem

`GoalSuggestionsSection` in `HomeView` is a separate scroll section with a "SUGGESTED GOALS" header and one full `GoalSuggestionCard` per exercise. Each card contains: exercise name/emoji, headline copy, NOW → SUGGESTED comparison with large numbers, and two action buttons (Apply / Keep as is).

This is heavy UI for an infrequent, optional feature. It appears below all exercise cards, which means users with 3+ exercises may never scroll down to see it. And the card exists in isolation — detached from the exercise it's about.

## Change

Remove `goalSuggestionsSection` from `HomeView` and delete `GoalSuggestionCard.swift`.

Instead, add an inline suggestion nudge inside `ExerciseCard` when a recommendation exists for that exercise. It appears below the progress bar as a single compact row:

```
↑ Suggested: 35 reps  ·  [Apply]  [✕]
```

- Arrow + label on the left (increase = `successGreen`, decrease = `.secondary`)
- `Apply` pill button: taps through `onApply` callback, dismisses inline
- `✕` icon button: dismisses inline without applying

Nudge only visible when `recommendation != nil`. Animated in/out with `.transition(.opacity.combined(with: .move(edge: .bottom)))`.

## ExerciseCard API change

```swift
struct ExerciseCard: View {
    // Add:
    var recommendation: GoalRecommendation? = nil
    var onApplyRecommendation: ((Int) -> Void)? = nil
}
```

## HomeView wiring

`HomeView` computes `activeGoalRecs` (already exists) and passes the matching rec to each `ExerciseCard`:

```swift
ExerciseCard(
    exercise: exercise,
    current: viewModel.totalReps(for: exercise),
    goal: viewModel.goal(for: exercise),
    recommendation: activeGoalRecs.first { $0.exercise == exercise },
    onApplyRecommendation: { newGoal in viewModel.setGoal(newGoal, for: exercise) },
    onIncrement: { amount in viewModel.logReps(amount, for: exercise, context: modelContext) }
)
```

`dismissedRecs` state and the dismiss callback move into `ExerciseCard` local state.

## Files

- `Just Reps/Views/HomeView.swift` — remove `goalSuggestionsSection`, update `ExerciseCard` call sites
- `Just Reps/Components/ExerciseCard.swift` — add inline nudge
- `Just Reps/Components/GoalSuggestionCard.swift` — **delete**

## Acceptance

- No `GoalSuggestionCard` or "SUGGESTED GOALS" section on HomeView
- When a rec exists for an exercise, the nudge appears inline in that card below the progress bar
- Apply updates goal immediately and nudge disappears
- ✕ dismisses nudge without changing goal
- No rec → no nudge row, card layout unchanged
