# Advanced Analytics

> Numbers that mean something.

---

## Summary

A premium analytics view with deeper patterns from the user's history: best day of the week, time-of-day distribution, volume trends, and personal records. Presented as clean stat cards — no charts for the sake of charts.

---

## Why it fits the brand

Basic stats (streak, heatmap) are free and always will be. Advanced analytics reward long-term users who want to understand their patterns — without turning the app into a fitness dashboard. Every number shown must answer a real question.

---

## Stats to include

### Consistency patterns
| Stat | Description |
|------|-------------|
| Best day of the week | Weekday with highest logging rate |
| Best time of day | Morning / Afternoon / Evening distribution |
| Longest active window | Consecutive weeks with at least 5/7 days |
| Current vs. average streak | How this streak compares to personal average |

### Volume trends
| Stat | Description |
|------|-------------|
| This week vs. last week | Total reps comparison |
| Monthly volume chart | Last 6 months, one bar per month |
| Personal records | Highest single-session rep count per exercise |
| All-time total | Already on History — surfaced here with breakdown |

### Goal analytics
| Stat | Description |
|------|-------------|
| Goal hit rate | % of days where all goals were met (last 30 days) |
| Goals streak | Already on home screen — historical view here |
| Average reps per session | Per exercise |

---

## Design

- Accessed via a new "Analytics" section in the Streak tab, below the heatmap
- Or: separate tab replacing the current Streak tab (streak stats move to a card within it)
- Each stat is a small card with a number, label, and optional mini chart
- **No empty states with fake data.** If there's less than 7 days of data, the stat doesn't appear.

---

## Acceptance criteria

- [ ] All stats calculated from local `WorkoutEntry` data (no backend required)
- [ ] Stats only appear with sufficient data (minimum threshold per stat)
- [ ] Gated behind "Premium" unlock
- [ ] No loading states — all calculations synchronous on the device
- [ ] Empty state for new users: "Come back after a week." (honest, brand-aligned)
