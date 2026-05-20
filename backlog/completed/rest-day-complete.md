# Rest Day Toggle

> Recovery is part of the discipline.

---

## Summary

Users can mark a day as an intentional rest day. Rest days don't break the streak and don't count against monthly consistency — but they can't be added retroactively, and you can only take one per week.

---

## Why it fits the brand

The brand is about sustainable habits, not punishment. Someone who takes a planned Sunday rest shouldn't feel like they failed. But the feature must have enough friction to stay honest — this isn't a "skip day" button.

---

## User story

> As someone who runs on weekends and doesn't do bodyweight work that day, I want to log it as a rest day so my streak survives without logging fake reps.

---

## Design

- **Access:** Long-press on today's date in the heatmap → "Mark as Rest Day"
- **Constraint:** Max 1 rest day per 7-day window. If the limit is hit, the option is greyed out with the message: *"One rest day per week."*
- **Visual:** Rest days appear as a faint `—` dash cell in the heatmap (neutral, not green)
- **Streak logic:** Rest days are treated as "present" for streak continuity, but excluded from goals-streak calculation
- **Copy on home screen:** If today is marked as rest: *"Rest day. See you tomorrow."*

---

## Acceptance criteria

- [ ] Long-press on today in heatmap shows context menu
- [ ] "Mark as Rest Day" inserts a `WorkoutEntry` tagged `.rest` for today
- [ ] Rest days don't break `loggedStreak`
- [ ] Rest days excluded from `goalsStreak` calculation
- [ ] Max 1 rest day per rolling 7 days, enforced in `HomeViewModel`
- [ ] Heatmap renders rest days with a distinct neutral cell style
- [ ] Cannot mark past days as rest retroactively

---

## What this is NOT

- Not a way to skip any day without consequence
- Not available for days already missed (no retroactive rest)
