# Annual Recap

> One year in three numbers.

---

## Summary

On January 1st, a single ephemeral card appears in the Streak tab showing three facts from the previous calendar year: longest streak, total days logged, and most consistent exercise. It disappears after 24 hours or a tap. Three numbers. One sentence each. Nothing else.

This is distinct from `year-one-view.md` (a permanent heatmap unlocked on the app's anniversary, seen once) and `month-recap.md` (a monthly logged-day count). Annual Recap is a recurring, lightweight reflection at the natural year boundary — for users who have been using the app long enough to have a year worth reflecting on.

---

## Why it fits the brand

January 1st is the one moment every year when people naturally reflect on consistency. Every wellness app floods this moment with dashboard summaries, goal-setting prompts, and year-over-year comparisons. Just Reps says three true things and leaves. The constraint is the feature. Showing up 218 days last year is either meaningful to the user or it isn't — the app doesn't editorialize.

---

## User story

> As someone who has been logging for over a year, I want to see a quiet summary of how consistent I was last year — three numbers, nothing more — so I can appreciate what I built without the app turning it into a performance review.

---

## Design

### Card layout

```
┌─────────────────────────────────┐
│  Last year.                     │
│                                 │
│  218 days logged.               │
│  Longest streak: 34.            │
│  Most consistent: Push-ups.     │
└─────────────────────────────────┘
```

- **Position:** Top of `StreakView`, above the streak stats row — same placement as `month-recap.md`
- **Background:** `AppTheme.Colors.darkBackground`
- **Typography:**
  - `"Last year."` — `AppTheme.Typography.caption`, wide letter-spacing, all-caps, secondary label colour
  - The three data lines — `AppTheme.Typography.body`, primary label colour
- **Dismiss:** Tap anywhere on the card. Fades with 0.2s opacity animation.
- **Auto-expiry:** 24 hours after January 1st, whether seen or not. `UserDefaults` records expiry.
- **No share button on the card itself.** The existing Share Streak Card in the toolbar captures this intent.
- **No CTA.** No "Set a goal for this year." No comparison to prior years. The card is a statement, not a prompt.

### Data calculations

```swift
struct AnnualRecapData {
    let year: Int                  // previous calendar year
    let daysLogged: Int            // unique logical days with ≥1 WorkoutEntry in [year]
    let longestStreak: Int         // longest unbroken streak occurring within [year]
    let mostConsistentExercise: ExerciseType  // exercise with most unique logged days in [year]
}

// Computed in StreakViewModel on January 1st
func computeAnnualRecap(for year: Int, entries: [WorkoutEntry]) -> AnnualRecapData? {
    let yearEntries = entries.filter {
        Calendar.current.component(.year, from: StreakEngine.logicalDay(date: $0.timestamp)) == year
    }
    guard !yearEntries.isEmpty else { return nil }
    // ... standard streak + grouping logic
}
```

### Gating conditions

| Condition | Behaviour |
|-----------|-----------|
| First January 1st after install (less than ~12 months of data) | Card does not appear |
| 0 days logged in prior calendar year | Card does not appear |
| User opens app on Jan 2nd having never seen the card | Card does not appear (24h window closed) |
| Multiple exercises tied for most consistent | First by home screen order wins |

### UserDefaults keys

```swift
lastSeenAnnualRecapYear: Int  // e.g. 2025 — prevents re-showing in the same year
annualRecapExpiresAt: Date    // set to Jan 2 at the user's 3AM logical day boundary
```

### First install condition

- The card requires at least **11 calendar months of data** in the prior year to appear.
- Computed as: `firstLaunchDate` is before February 1st of the prior year.
- Users who installed in November and see January 1st have too little data for a meaningful recap.

---

## Acceptance criteria

- [ ] Card appears in `StreakView` on January 1st only — not any other day
- [ ] Card does not appear if the user installed after January 31st of the prior year
- [ ] Card does not appear if 0 days were logged in the prior calendar year
- [ ] Card shows exactly three data lines: days logged, longest streak, most consistent exercise
- [ ] Copy format: `"[N] days logged."` / `"Longest streak: [N]."` / `"Most consistent: [Exercise]."`
- [ ] Tapping the card dismisses it with 0.2s fade; `lastSeenAnnualRecapYear` written to UserDefaults
- [ ] Card auto-expires after 24h if not tapped
- [ ] Card never re-appears after dismissal or expiry for the same year
- [ ] `longestStreak` is calculated from within the prior calendar year only (not all-time)
- [ ] `mostConsistentExercise` is the exercise with the most unique logged days in the prior year

---

## What this is NOT

- Not a year-over-year comparison — prior years are not referenced
- Not a goal-setting prompt — no "What will you do this year?" CTA
- Not the Year-One View (`year-one-view.md`) — that is a permanent heatmap unlocked once on app anniversary; this is an ephemeral annual card
- Not a push notification — discovered only by opening the app on January 1st
- Not a dashboard — three lines of text, nothing more
- Not shareable from the card itself — users who want to share use the existing Share Streak Card
