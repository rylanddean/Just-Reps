# Fix: Goal suggestion decrease arrow color

**Status:** Ready  
**Effort:** XS  
**Risk:** None

## Problem

`GoalSuggestionCard` uses `AppTheme.Colors.streakDanger` (red) for the downward arrow when a decrease is recommended. Per the brand spec, `streakDanger` is reserved exclusively for at-risk states. A goal decrease is a neutral, even positive adjustment ("Ease into it.") — it should never read as alarming.

## Change

In `GoalSuggestionCard.swift`, replace the decrease arrow color:

```swift
// Before
.foregroundStyle(recommendation.direction == .increase
                 ? AppTheme.Colors.successGreen
                 : AppTheme.Colors.streakDanger)

// After
.foregroundStyle(recommendation.direction == .increase
                 ? AppTheme.Colors.successGreen
                 : Color(UIColor.secondaryLabel))
```

## Files

- `Just Reps/Components/GoalSuggestionCard.swift`

## Acceptance

- Decrease recommendation arrow is grey/secondary, not red
- Increase recommendation arrow remains `successGreen`
