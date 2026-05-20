# Ghost Streak

> A quiet reminder of what you've done before.

---

## Summary

When the current streak is shorter than the user's all-time best, the previous best appears as a faint secondary number in the streak header — no label needed, no explanation, just there. When the current streak surpasses the best, the ghost disappears.

---

## Why it fits the brand

Streak loss in most apps is dramatic: badges reset, notifications fire, guilt copy appears. Just Reps handles it quietly. The ghost streak is silent accountability — a reference point, not a judgement. It rewards the user who already knows what they're capable of without telling them what to do about it.

---

## User story

> As someone who broke a 47-day streak and is rebuilding, I want to see my best streak as a reminder — so I have something to aim for without the app nagging me.

---

## Design

- **Placement:** In the Rep Streak cell of the dual header, below the large streak number.
- **Display:** Small caption text. Format: `best: 47` — no decoration, no icon.
- **Colour:** `Color(UIColor.tertiaryLabel)` — faint, clearly secondary.
- **Visibility:** Only shown when `currentStreak < longestStreak`. Hidden when equal or exceeding (the ghost is gone — you're at your best).
- **No animation** on reveal or hide.

```swift
// In streakCell view
if currentStreak < longestStreak {
    Text("best: \(longestStreak)")
        .font(AppTheme.Typography.caption)
        .foregroundStyle(Color(UIColor.tertiaryLabel))
}
```

---

## Acceptance criteria

- [ ] Ghost number appears in the Rep Streak cell when current < longest
- [ ] Ghost is hidden when current streak equals or exceeds longest
- [ ] Ghost uses tertiary label colour (adapts to light/dark mode)
- [ ] `longestStreak` sourced from `StreakEngine` — not a separate UserDefaults key
- [ ] No animation, no transition — it's just there or it isn't

---

## What this is NOT

- Not a badge or achievement for reaching the ghost
- Not labelled "personal best" or "record" — bare `best: N` only
- Not shown for the Goal Streak cell (rep streak only)
- Not something the app draws attention to
