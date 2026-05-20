# Watch: Distinct haptic on full goal completion

**Status:** Ready  
**Effort:** XS  
**Risk:** None

## Problem

Every rep log plays `.click`. When the last goal is met and `allGoalsMet` flips to `true`, nothing distinguishes that moment from any other tap. A distinct haptic makes completion feel earned without any visual fanfare — consistent with the brand's understated celebration style.

## Change

### `WatchHomeView.swift`

Track the previous `allGoalsMet` state and fire `.success` when it first becomes true in the current session.

```swift
struct WatchHomeView: View {
    var vm: WatchViewModel
    var context: ModelContext
    @State private var wasAllGoalsMet = false

    var body: some View {
        ScrollView { ... }
        .onChange(of: vm.allGoalsMet) { _, newValue in
            if newValue && !wasAllGoalsMet {
                WKInterfaceDevice.current().play(.success)
            }
            wasAllGoalsMet = newValue
        }
    }
}
```

The `.success` pattern (two short taps) is meaningfully different from `.click` (single tap) — the user feels the difference without looking at the screen.

## Files

- `Just Reps Apple Watch Watch App/WatchHomeView.swift`

## Acceptance

- Logging the final rep that completes all goals plays `.success` haptic once
- Subsequent rep logs on already-completed exercises play `.click` as before
- No haptic fires on app launch even if goals were already met
