# Fix: Rename `…` custom entry button to a legible affordance

**Status:** Ready  
**Effort:** XS  
**Risk:** None

## Problem

The `…` (ellipsis) button on `ExerciseCard` opens a custom rep entry sheet. Nothing about `…` communicates "enter a number." New users likely ignore it, defaulting only to the preset increment buttons (+5, +10, +25).

## Change

Replace the ellipsis icon with `Image(systemName: "number")` to signal a numeric input action:

```swift
// Before
Image(systemName: "ellipsis")

// After
Image(systemName: "number")
```

Keep the button's layout, sizing, background, and behavior identical.

## Files

- `Just Reps/Components/ExerciseCard.swift`

## Acceptance

- Custom entry button shows a `#` symbol instead of `…`
- Button still opens `CardCustomRepEntry` sheet
- Layout is unchanged
