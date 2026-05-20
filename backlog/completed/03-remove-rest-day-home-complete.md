# Cleanup: Remove rest day button from HomeView

**Status:** Complete  
**Effort:** XS  
**Risk:** None

## Problem

The rest day action is accessible from two places:
1. A small plain-text `Rest day` button in the HomeView scroll area
2. A heatmap cell tap on the StreakView (already wired up)

Two surfaces for the same action is inconsistent. The HomeView button has minimal visual weight and is easy to miss. The heatmap is a more intuitive location — it's spatially adjacent to past rest days and makes the calendar intent clear.

## Change

Remove `restDayButton` and its conditional from `HomeView`:

```swift
// Remove:
if viewModel.canMarkRestDay {
    restDayButton
}

// Remove the private var restDayButton implementation
```

The `canMarkRestDay` computed property on `HomeViewModel` can stay — the StreakView's `canMarkRestDay` computed property already uses the same logic and is independent. No model changes needed.

## Files

- `Just Reps/Views/HomeView.swift`

## Acceptance

- No rest day button visible on the Home screen
- Rest day can still be marked via heatmap tap on StreakView
- `viewModel.canMarkRestDay` still compiles (other code may reference it; don't delete from ViewModel)
