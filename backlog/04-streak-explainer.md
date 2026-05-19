# Feature: Streak header explainer — one-time tooltip

**Status:** Ready  
**Effort:** S  
**Risk:** None

## Problem

The dual streak (REP STREAK + GOAL STREAK) is the most unique feature of Just Reps. First-time users see two large numbers and two all-caps labels and have no idea why they're different, why the goal streak is often 0 while the rep streak grows, or why they should care about building the goal streak.

The most differentiating feature has zero explanation.

## Behaviour

- When the user has never seen the explainer (`@AppStorage("hasSeenStreakExplainer")` is false), the streak header shows a small `?` indicator (capsule tag or info icon) adjacent to one of the labels.
- Tapping anywhere on the streak header area opens a bottom sheet.
- Sheet content:

> **Two streaks.**
>
> Rep Streak counts any day you log reps — even 5. Hard to break.
>
> Goal Streak counts days you hit every goal. Harder to hold. Worth building.

- Single `Got it` button dismisses and sets `hasSeenStreakExplainer = true`.
- Never shown again after dismissal.

## Implementation notes

- `@AppStorage("hasSeenStreakExplainer") private var hasSeenStreakExplainer = false` in `HeaderCardView` or `HomeView`.
- Bottom sheet uses `.presentationDetents([.height(260)])`.
- Sheet uses the same card/capsule visual language as the rest of the app — no stock Form or Alert.
- The `?` indicator is `AppTheme.Colors.coolBlue` (subtle, non-alarming) and disappears once seen.

## Files

- `Just Reps/Components/HeaderCardView.swift`
- New: `Just Reps/Components/StreakExplainerSheet.swift`

## Acceptance

- First launch: `?` indicator visible on streak header
- Tap opens bottom sheet with correct copy
- `Got it` dismisses and persists `hasSeenStreakExplainer = true`
- Re-launch: no indicator shown, no sheet
