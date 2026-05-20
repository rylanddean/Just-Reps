# Month Recap

> One quiet moment at the close of the month.

---

## Summary

On the first day of each month, a single inline card appears at the top of the Streak tab showing last month's logged-day count. It reads: `"You showed up X of Y days in [Month]."` No chart, no breakdown, no comparison. It disappears after being seen (tap anywhere on the card, or after 24 hours). It never appears again for that month.

---

## Why it fits the brand

Month boundaries are natural moments of reflection. Every fitness app floods this moment with analytics, charts, and "goals for next month" prompts. Just Reps says one honest thing and leaves. The constraint is the feature — the discipline of *not* adding more copy or actions here is what makes this moment feel earned rather than manufactured. It also gives the app a reason to open on the first of the month without sending a notification.

---

## User story

> As a regular user, I want to know how consistent I was last month without having to do math from the heatmap — so I can appreciate the habit I'm building without the app turning it into a report.

---

## Design

### Card layout

```
┌──────────────────────────────┐
│  You showed up               │
│  23 of 31 days in April.     │
└──────────────────────────────┘
```

- **Position:** Top of `StreakView`, above the streak stats row. Only visible on day 1 of the month and only until dismissed or 24h has elapsed.
- **Background:** `AppTheme.Colors.darkBackground` — standard card style
- **Typography:** Two lines. Line 1: `AppTheme.Typography.body` in secondary label colour. Line 2: `AppTheme.Typography.headline` in primary label colour.
- **Dismiss:** Tap anywhere on the card. Fades out with a 0.2s opacity animation. That's the only animation.
- **No share button.** No "See details" link. No CTA. It's a statement, not a prompt.

### Logic

```swift
// Written to UserDefaults on dismiss or expiry
lastSeenMonthRecap: String  // e.g. "2026-04" — prevents re-showing

// Calculation
let lastMonthDays = // all logical days in previous calendar month with ≥1 WorkoutEntry
let daysInMonth = // calendar days in previous month
// copy: "You showed up \(lastMonthDays) of \(daysInMonth) days in \(monthName)."
```

- Only calculated from existing `WorkoutEntry` records — no new data required
- Uses `StreakEngine.logicalDay(for:)` to determine which calendar month each entry belongs to
- Does not appear in the first calendar month after install (insufficient history)
- Does not appear if the user has 0 days logged last month

### Edge cases

| Case | Behaviour |
|------|-----------|
| 0 days logged last month | Card does not appear |
| First month after install | Card does not appear |
| User opens app on day 2 without having seen it | Card does not appear (the window closed) |
| All 31 days logged | Copy: `"You showed up 31 of 31 days in March."` — no special treatment |

---

## Acceptance criteria

- [ ] Card appears in `StreakView` on the 1st day of each month, top of the screen
- [ ] Card does not appear if 0 days were logged last month
- [ ] Card does not appear in the first month after install
- [ ] Copy uses exact format: `"You showed up X of Y days in [Month]."`
- [ ] Tapping the card dismisses it with a 0.2s fade; `UserDefaults` records dismissal
- [ ] Card automatically expires after 24h even if not tapped
- [ ] Card never re-appears for the same month
- [ ] No share, export, or action affordance on the card

---

## What this is NOT

- Not a push notification — the card is discovered by opening the app
- Not a yearly summary (that's Year-One View)
- Not a streak summary — it counts logged days, not streak continuity
- Not a performance review — no "best exercise" or "total reps" data
- Not persistent — one glimpse and it's gone
