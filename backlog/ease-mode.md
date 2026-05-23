# Ease Mode

> Still counts. Just less.

---

## Summary

A week-long mode that temporarily halves all daily rep goals. Activate it with a single tap from Settings or a long-press on any exercise card. The streak continues as long as the reduced goals are met. After 7 days, goals return to normal automatically — no action required. No explanation is asked for. The app never questions the decision.

This is not a rest day. The user still shows up. They just show up for less, and that's enough.

---

## Why it fits the brand

The brand celebrates showing up over performance. But right now, the app offers two options when life gets hard: hit the full goal, or break the streak. Ease Mode adds a third: show up anyway, at whatever level is realistic. This is consistent with how discipline actually works — it bends before it breaks. The most important habit is the one that survives a hard week.

Every major habit app that has introduced a grace mechanic has seen retention improve. Ease Mode is Just Reps' version — and unlike streak freezes or rest days, it still requires showing up. That distinction matters.

---

## User story

> As someone dealing with a tough week at work, I want to cut my goals in half so I can still log something every day — without my streak evaporating because I couldn't hit my usual numbers.

---

## Design

### Activation

Two entry points:

**1. Settings → "Ease Mode"**
- A row in the goals section. Label: `"Ease Mode"`. Sub-label: `"Halve your goals for 7 days."`
- Tapping opens a simple confirmation sheet (not a modal): `"Goals will be halved for 7 days. Your streak continues if you hit the reduced goals."` — one button: `"Start easy week"`.

**2. Long-press on any exercise card**
- Context menu item: `"Start easy week"`
- Same confirmation sheet as above. Applies to all exercises, not just the one long-pressed.

### While active

- **Goal values are halved** (rounded up to the nearest 5 for pill-button friendliness — e.g., a goal of 30 becomes 15; a goal of 25 becomes 15).
- **Progress bars** reflect the halved goals. A user who hits 15 of a halved-15 goal sees a full bar.
- **Pill buttons** are unchanged (+5 / +10 / +25). The user can exceed the halved goal freely.
- **Streak logic** uses the halved goal thresholds only. Hitting the original goal is not required.
- **A single quiet indicator** in Settings → Ease Mode row shows the remaining days: `"Active — 5 days left"` in secondary label colour. Nothing on the home screen.
- **No banner, no badge, no home screen indicator.** The app doesn't announce the mode — it just behaves differently.

### Expiry

- After exactly 7 calendar days, goals return to their original values.
- No notification. No fanfare. The row in Settings returns to its default state.
- If the user logged enough to hit original goals every day during easy week, no special acknowledgment — it's just a week, logged like any other.

### Edge cases

| Case | Behaviour |
|------|-----------|
| Goal is 5 (can't halve cleanly) | Halved goal = 5 (minimum 1 rep; no goal below 5) |
| User manually changes a goal during easy week | The changed goal is halved from that point forward |
| Ease Mode expires mid-streak | Goals revert instantly on day 8; no grace period |
| User activates Ease Mode again immediately after it expires | Allowed — no lock-out period |
| Rest Day is taken during Ease Mode | Rest Day logic is unchanged; the two coexist |

### Data model

```swift
// UserDefaults keys
easeModeStartDate: Date?      // nil when inactive
// Computed property in HomeViewModel:
var isEaseModeActive: Bool {
    guard let start = easeModeStartDate else { return false }
    return Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0 < 7
}
var easedGoal: Int {
    isEaseModeActive ? max(5, Int((Double(dailyGoal) / 2).rounded(.up) / 5) * 5) : dailyGoal
}
```

---

## Acceptance criteria

- [ ] Settings shows an "Ease Mode" row; tapping presents a confirmation sheet
- [ ] Long-press on any exercise card surfaces an "Start easy week" context menu item
- [ ] Confirming activation writes `easeModeStartDate` to UserDefaults
- [ ] All exercise goal thresholds are halved (rounded up to nearest 5) while active
- [ ] Progress bars reflect halved goals; `successGreen` fill when halved goal is met
- [ ] Streak calculation uses halved goal thresholds during active window
- [ ] Settings row shows `"Active — N days left"` in secondary label colour
- [ ] No home screen banner, badge, or visual indicator beyond the normal exercise cards
- [ ] Goals revert automatically after 7 days; no user action required
- [ ] Ease Mode can be deactivated early from Settings (confirmation sheet: `"End easy week early? Goals return to normal now."`)

---

## What this is NOT

- Not a rest day — logging still required; the goal is lower, not absent
- Not permanent — expires automatically after 7 days
- Not per-exercise — it applies to all active exercises simultaneously
- Not a badge or achievement — there's nothing to unlock by completing an easy week
- Not shameful — the app never frames Ease Mode as falling short. It's just a lighter week.
- Not visible to any accountability partner (see `accountability-pair.md`) — they see only logged/not logged status
