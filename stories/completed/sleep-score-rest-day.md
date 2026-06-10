# Sleep Score Rest Day

> Your body already said rest. The app just listened.

**Effort:** M
**Risk:** Low — additive feature, no changes to streak logic

## Summary

Read the user's Apple Health sleep score each morning. If it's below a configurable threshold (default: 60), quietly surface a rest day suggestion on the home screen. One tap to accept. The app never makes the call for the user — it just names what their body already signaled.

## Why it fits the brand

Just Reps doesn't coach. But it can notice. A rest day suggestion earned by a poor sleep score is different from skipping — it's earned recovery, and framing it that way reinforces the brand's respect for the whole athlete, not just the reps column. This is the same instinct as Calendar-Aware Rest Day: the app observes, offers once, then leaves you alone.

## User Story

> As someone who slept badly, I want the app to notice my sleep score and offer a rest day so I don't feel guilty skipping — I feel like I made a smart choice.

## Design

### Data source

`HKCategoryTypeIdentifier.sleepAnalysis` is already a declared HealthKit type in this project. Sleep score maps to `HKQuantityTypeIdentifier.appleSleepingWristTemperature` indirectly, but the cleaner path is Apple's **Sleep score** via `HKCategoryValueSleepAnalysis` stages — specifically reading total sleep duration and deep/REM share to compute a quality proxy. Alternatively, use `com.apple.health.SleepScore` if available on the device's OS.

Simpler V1: read total time asleep from the last night's `HKCategoryTypeIdentifier.sleepAnalysis` entries (`.asleepREM` + `.asleepDeep` + `.asleepCore`). If total < 5.5 hours, treat as a low-quality night.

V2 (iOS 18+): use `HKQuantityType(.sleepDurationGoal)` alongside `HKCategoryTypeIdentifier.sleepAnalysis` to compute a goal-relative score.

### Trigger

On app open each day (after 6 AM, before noon), `SleepAdvisorService.checkLastNight()` reads the previous night's sleep data from HealthKit. If quality is below threshold and no rest day is set today, set `pendingSleepRestSuggestion = true` on `HomeViewModel`.

### Card

When `pendingSleepRestSuggestion` is true and `canMarkRestDay` is also true, show a suggestion card in `HomeView` (same position as Calendar-Aware rest day card):

```
┌──────────────────────────────────────┐
│  Rough night.                        │
│  Rest day?                           │
│                          [ Yes ]     │
└──────────────────────────────────────┘
```

- **"Yes"**: calls existing `markRestDay()`, dismisses card, clears `pendingSleepRestSuggestion`
- **Dismiss**: clears `pendingSleepRestSuggestion` for today, no follow-up

### Settings

Add a toggle under Settings → Health: **"Suggest rest days after poor sleep"** (default on). No threshold configuration exposed — keep it simple.

## Files

- `Just Reps/Services/SleepAdvisorService.swift` — **new** — read sleep data, return quality verdict
- `Just Reps/ViewModels/HomeViewModel.swift` — add `pendingSleepRestSuggestion`, call service on load
- `Just Reps/Views/HomeView.swift` — render suggestion card when `pendingSleepRestSuggestion && canMarkRestDay`
- `Just Reps/Views/SettingsView.swift` — add toggle

## Acceptance Criteria

- [ ] HealthKit sleep read permission requested the first time the feature triggers (not on install)
- [ ] If total sleep < 5.5 hours (last night), `pendingSleepRestSuggestion` is set on app open (6 AM–noon only)
- [ ] Card only appears when `canMarkRestDay` is also true (no rest day already set, no workout entries today)
- [ ] "Yes" marks a rest day via existing mechanism; card disappears
- [ ] Dismissing clears the suggestion for the day; it doesn't reappear on subsequent app opens the same day
- [ ] Settings toggle disables the check entirely; changing it takes effect immediately
- [ ] No card if rest day already set or if `canMarkRestDay` is false for any other reason
- [ ] Feature is purely additive — no changes to streak or rest day logic

## What this is NOT

- Not a sleep tracker — Just Reps reads one data point to offer one option
- Not a coach — it observes a signal, offers once, moves on
- Not a notification — card appears on app open only
