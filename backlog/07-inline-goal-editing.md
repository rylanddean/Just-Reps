# Feature: Inline goal editing on ExerciseCard

**Status:** Ready  
**Effort:** M  
**Risk:** Low — additive change, Settings fallback stays until confirmed working

## Problem

Changing a daily goal requires: tap gear icon → scroll to Daily Goals → use stepper. This is the most common configuration action and it's buried 2 taps deep in Settings. The goal (`/ 30`) is displayed on the exercise card but is inert.

## Change

Make the `/ N` goal text on `ExerciseCard` a tappable target that opens a compact inline goal editor sheet.

### ExerciseCard header row

Wrap the `/ \(goal)` text in a `Button`:

```swift
Button { showGoalEditor = true } label: {
    Text("/ \(goal)")
        .font(AppTheme.Font.caption())
        .foregroundStyle(.secondary)
}
.buttonStyle(.plain)
```

`@State private var showGoalEditor = false` on `ExerciseCard`.

### Goal editor sheet

New component `InlineGoalEditorSheet`:

- `.presentationDetents([.height(260)])`
- Same layout as `CardCustomRepEntry`: large number field, unit label, confirm button
- Title: "Daily goal · [ExerciseName]"
- Keyboard type: `.numberPad`
- `Set Goal` button disabled until value > 0 and value != current goal
- On confirm: calls `onGoalChange(newGoal)` callback, dismisses

### ExerciseCard API addition

```swift
var onGoalChange: ((Int) -> Void)? = nil
```

### HomeView wiring

```swift
ExerciseCard(
    ...
    onGoalChange: { newGoal in viewModel.setGoal(newGoal, for: exercise) }
)
```

### Settings cleanup

Remove the `goalsSection` from `SettingsView`. Goals are now set inline. The section's header footer copy ("Daily Goals") can be removed along with the `ForEach` stepper rows. The `viewModel.setGoal` and `viewModel.goal` methods remain unchanged.

## Files

- `Just Reps/Components/ExerciseCard.swift` — tappable goal, sheet trigger
- New: `Just Reps/Components/InlineGoalEditorSheet.swift`
- `Just Reps/Views/HomeView.swift` — add `onGoalChange` to ExerciseCard call sites
- `Just Reps/Views/SettingsView.swift` — remove `goalsSection`

## Acceptance

- Tap `/ N` on any exercise card → goal editor sheet opens
- Sheet shows current goal pre-filled (or empty field, keyboard auto-focused)
- Setting a new value updates the card's goal immediately
- Stepper in Settings Daily Goals section is gone
- Goal changes persist across app restarts (same `UserDefaults` path, no model changes)
