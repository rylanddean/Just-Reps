# Watch: Show streak on home tab

**Status:** Ready  
**Effort:** XS  
**Risk:** None

## Problem

The first thing a user sees when they raise their wrist is the exercise card list. The streak — the core motivation of the app — requires a swipe to see. It should be visible immediately.

## Change

### `WatchHomeView.swift`

Add a compact streak indicator above the exercise cards. One line, right-aligned, non-intrusive.

```swift
var body: some View {
    ScrollView {
        VStack(spacing: 10) {
            // Streak indicator
            HStack {
                Spacer()
                Text("🔥 \(vm.loggedStreak)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(vm.loggedStreak > 0 ? WatchTheme.successGreen : .secondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 4)

            ForEach(vm.activeExercises) { exercise in
                WatchExerciseCard(exercise: exercise, vm: vm, context: context)
            }

            if vm.allGoalsMet {
                Text("Done. That's all it takes.")
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.successGreen)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}
```

## Files

- `Just Reps Apple Watch Watch App/WatchHomeView.swift`

## Acceptance

- Streak count is visible on the home tab without swiping
- Shows `successGreen` when streak > 0, secondary color at 0
- Does not push exercise cards below the fold on a 41mm watch
- Animates with `numericText` transition when streak increments
