# Apple Health Export

> Your reps count in the broader picture of your health.

---

## Summary

An opt-in setting that writes daily logged rep totals to Apple Health as strength training samples. When enabled, each day's logged reps post to HealthKit as a `HKWorkout` of type `.traditionalStrengthTraining`. The user's Activity rings get credit. Nothing else changes.

---

## Why it fits the brand

This is a silent integration — one Settings toggle, no UI changes to the logging flow, no new screens. It adds value to users who care about their Health app data without cluttering the experience for those who don't. It also positions Just Reps as a legitimate contributor to the Apple Health ecosystem rather than an isolated silo, which matters for long-term user retention.

---

## User story

> As someone who tracks my Activity rings daily, I want my Just Reps sessions to count toward my Exercise ring — so my Health data reflects what I actually did.

---

## Design

### Settings toggle

- **Location:** Settings → row labelled "Apple Health"
- **Sub-label:** "Share your logged reps with the Health app."
- **Behaviour:** Tapping for the first time triggers `HKHealthStore.requestAuthorization`. If denied, the toggle stays off and a brief note appears: "Enable in Health → Data Access & Devices → Just Reps."
- **No onboarding screen.** One toggle. Done.

### What gets written

| HealthKit type | Value |
|----------------|-------|
| `HKWorkoutActivityType` | `.traditionalStrengthTraining` |
| Duration | `nil` — Just Reps doesn't track time |
| Total energy | `nil` — Just Reps doesn't track calories |
| Metadata | `[HKMetadataKeyExternalUUID: entry.id]` |

One `HKWorkout` sample per day, written after the user's first rep of the day. If more reps are added later, the existing sample is updated (delete + re-insert with same external UUID).

### What does NOT get written

- Individual exercise names — HealthKit has no "pushup count" quantity type in a way that maps cleanly to Just Reps' model; writing a generic workout is honest and avoids false precision.
- Rep counts as quantities — there is a `HKQuantityType(.pushUpCount)` type, but it requires one sample per exercise and implies a specific modality. Out of scope for V1 of this feature.
- Historical data — only future days after the toggle is enabled. No backfill.

### When writing occurs

- On first rep logged in a day (creates the HKWorkout)
- On subsequent rep logging (updates via delete + re-insert)
- Uses a background `Task` — never blocks the UI

---

## Acceptance criteria

- [ ] Settings row "Apple Health" with toggle, off by default
- [ ] First enable triggers `HKHealthStore.requestAuthorization` for `.workout` write permission
- [ ] If authorization denied, toggle remains off; brief note shown inline
- [ ] First rep of the day creates one `HKWorkout` sample of type `.traditionalStrengthTraining`
- [ ] Subsequent reps update the existing sample (delete + re-insert, same external UUID)
- [ ] No historical data is written — only from enable date forward
- [ ] Logging flow is unchanged — no new UI, no confirmation, no spinner
- [ ] Works correctly with the 3AM logical day boundary

---

## What this is NOT

- Not a two-way sync — Health data is never read back into Just Reps
- Not a source of truth — Just Reps' own SwiftData store is authoritative
- Not a calorie or time tracker — duration and energy are `nil`
- Not a default-on integration — explicit opt-in only
