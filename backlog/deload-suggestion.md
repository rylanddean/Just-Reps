# Deload Suggestion

> You've been consistent. Maybe ease off this week.

---

## Summary

After six or more consecutive weeks of meeting daily goals, the app surfaces a single dismissible card in the Streak tab: a quiet acknowledgment that sustained consistency has been earned, and that a lighter week might be worth taking. One action links directly to Ease Mode. The other dismisses the card forever for that cycle. No algorithm. No heart rate data. Just a counter and a nudge grounded in basic exercise science.

---

## Why it fits the brand

Just Reps doesn't coach. But it can notice. Eight weeks of unbroken goal-hitting is a specific, verifiable fact — and acknowledging it with a gentle suggestion is not coaching, it's witnessing. The brand says "showing up matters more than how many." A deload week is showing up at reduced intensity, which is exactly what the brand believes in.

This is also the only place Just Reps engages with exercise science directly — and it does so in the quietest possible way: one card, one sentence, one optional action.

---

## User story

> As someone who has been hitting my goals every day for nine weeks, I want the app to notice — and maybe suggest it's okay to back off a little — so I don't feel like I'm cheating when I take a lighter week before I burn out.

---

## Design

### Trigger condition

```swift
// Computed in HomeViewModel or StreakViewModel
var consecutiveWeeksOfGoalsMet: Int {
    // Count the number of complete calendar weeks (Mon–Sun) in the last 90 days
    // where every logged day within the week met or exceeded the daily goal
    // A week counts only if the user was active (had at least 5 logged days)
}
```

**Fires when:**
- `consecutiveWeeksOfGoalsMet >= 6`
- The user has not been shown a deload card in the last 8 weeks (`lastDeloadSuggestionDate` in UserDefaults)
- Ease Mode is not already active
- Just Show Up Mode is not already active

**Fires at most once per 8-week cycle.** Whether dismissed or acted on, the suggestion does not re-appear until the condition is met again from that point.

### Card layout

```
┌──────────────────────────────────────┐
│  [N] weeks consistent.               │
│  Your body might want a lighter one. │
│                                      │
│  [ Make this week lighter ]          │
└──────────────────────────────────────┘
```

- **Position:** Top of `StreakView`, above the streak stats row. Below the Annual Recap card if both are visible (unlikely but possible on January 1st of a consistent year).
- **Background:** `AppTheme.Colors.darkBackground`
- **Typography:**
  - First line: `AppTheme.Typography.headline`, primary label colour
  - Second line: `AppTheme.Typography.body`, secondary label colour
  - Button: standard pill button, `AppTheme.Colors.coolBlue` background (not `successGreen` — this is not a completion state, it's a suggestion)
- **Dismiss:** Swipe down on the card, or tap anywhere outside the button. No explicit × button — the gesture is sufficient.
- **The button:** `"Make this week lighter"` — tapping activates Ease Mode (see `ease-mode.md`) and dismisses the card.

### Copy

| Weeks | First line |
|-------|-----------|
| 6 | `"Six weeks consistent."` |
| 7 | `"Seven weeks consistent."` |
| 8+ | `"[N] weeks consistent."` |

Second line is always: `"Your body might want a lighter one."`

No exclamation points. No superlatives. No coaching. The sentence is descriptive, not prescriptive.

### Ease Mode integration

Tapping "Make this week lighter" is equivalent to activating Ease Mode from Settings — it writes `easeModeStartDate` to UserDefaults and halves goals for 7 days. See `ease-mode.md` for complete Ease Mode behaviour.

If Ease Mode is already active when the suggestion would otherwise fire, the card is suppressed for that cycle and the cycle resets from the Ease Mode end date.

### UserDefaults keys

```swift
lastDeloadSuggestionDate: Date?  // set when card is shown; nil if never shown
// Prevents re-showing for 8 weeks regardless of dismissal or activation
```

### No tracking of whether the user acted

The app records when the suggestion was shown — not whether the user took it. No analytics. No follow-up. No "last time you took a lighter week" memory.

---

## Acceptance criteria

- [ ] Card appears in `StreakView` when `consecutiveWeeksOfGoalsMet >= 6`
- [ ] Card does not appear if Ease Mode or Just Show Up Mode is already active
- [ ] Card does not appear if shown within the last 8 weeks
- [ ] First line shows the correct week count (`"Six weeks consistent."` / `"[N] weeks consistent."`)
- [ ] `"Make this week lighter"` button activates Ease Mode and dismisses the card
- [ ] Dismissing by swipe/tap outside suppresses the card for 8 weeks (same as acting on it)
- [ ] `lastDeloadSuggestionDate` is written to UserDefaults on card display
- [ ] Card is absent when Ease Mode activates from any other entry point (Settings, long-press)
- [ ] `consecutiveWeeksOfGoalsMet` only counts complete calendar weeks with ≥5 logged days

---

## What this is NOT

- Not a directive — the card observes; the user decides
- Not based on biometric data — no heart rate, no sleep, no HRV integration
- Not a rest day — it links to Ease Mode (reduced goals) not Rest Day (no logging required)
- Not shown in the first 6 weeks of app use (by definition — the trigger requires 6 weeks)
- Not a push notification — discovered only by opening the Streak tab
- Not a recurring weekly check-in — fires at most once every 8 weeks, and only after the streak condition is met
- Not a judgment if ignored — there is no "are you sure?" and no follow-up if dismissed
