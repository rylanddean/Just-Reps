# Goal Suggestion Cooldown

> Apply a suggestion. Don't get nagged again two minutes later.

**Effort:** S
**Risk:** Low — service-layer change, no model changes

## Problem

When a user applies a goal change from the inline suggestion nudge on an `ExerciseCard` (or from the Pulse tab's `GoalAdvisorService` recs), `GoalAdvisorService.recommendations(for:)` immediately re-evaluates against the same 7-day window and can produce another suggestion for the same exercise moments later. The user just accepted the advice — surfacing a new recommendation right away feels broken and undermines confidence in both suggestions.

## User Story

> As someone who just bumped my pushup goal from the app's suggestion, I don't want the app to immediately recommend another change — I need time to settle into the new goal before it weighs in again.

## Change

Add a per-exercise cooldown to `GoalAdvisorService`. After a goal change is applied, record a `goalLastApplied` timestamp for that exercise in `UserDefaults`. `recommendations(for:)` filters out any exercise whose `goalLastApplied` is within the last 7 days.

```swift
// GoalAdvisorService.swift
static func recordGoalApplied(for exercise: ExerciseType) {
    let key = "goalAdvisor.lastApplied.\(exercise.rawString)"
    UserDefaults.standard.set(Date(), forKey: key)
}

private static func isOnCooldown(_ exercise: ExerciseType) -> Bool {
    let key = "goalAdvisor.lastApplied.\(exercise.rawString)"
    guard let lastApplied = UserDefaults.standard.object(forKey: key) as? Date else { return false }
    return Date().timeIntervalSince(lastApplied) < 7 * 86_400
}
```

Call `recordGoalApplied(for:)` from the `onApplyRecommendation` callback in `ExerciseCard` and from the goal-recs Apply action in `PulseView`, alongside the existing `setGoal(_:for:)` call.

## Files

- `Just Reps/Services/GoalAdvisorService.swift` — add cooldown check + `recordGoalApplied`
- `Just Reps/Components/ExerciseCard.swift` — call `recordGoalApplied` on Apply
- `Just Reps/Views/PulseView.swift` — call `recordGoalApplied` on Apply

## Acceptance Criteria

- [ ] Applying a recommendation (via ExerciseCard nudge or Pulse tab) silences that exercise's suggestion for 7 days
- [ ] After 7 days, the exercise is eligible for a new recommendation again
- [ ] Dismissing (✕) without applying does **not** start the cooldown
- [ ] The cooldown is per-exercise — applying a pushup suggestion doesn't affect pullup suggestions
- [ ] Cooldown persists across app launches (stored in `UserDefaults`)
