# Expanded Achievements

> Milestones should feel earned, not manufactured.

---

## Summary

Expand the current 7-achievement set to ~20, covering streaks, total volume, consistency patterns, and specific exercises. Achievements are discovered silently — no push notification, just a quiet badge on the Streak tab.

---

## Why it fits the brand

Subtle gamification rewards consistency without turning the app into a game. The goal is a moment of quiet satisfaction, not a dopamine hijack.

---

## Design principles

- **Silent unlock:** Badge appears on the Streak tab icon. No interrupt, no animation storm.
- **Retroactive:** Achievements are evaluated against all-time history on every app launch — old data can unlock new badges.
- **No fake tiers:** One achievement per concept. No bronze/silver/gold for the same thing.
- **Copy tone:** Understated. "Built Daily" not "🏆 LEGENDARY WARRIOR 🏆"

---

## Proposed achievement set

### Streak milestones
| Badge | Condition | Copy |
|-------|-----------|------|
| First Rep | Log 1 rep ever | "It starts here." |
| First Week | 7-day streak | "Seven days straight." |
| Two Weeks | 14-day streak | "Habit forming." |
| 30 Days | 30-day streak | "One month in." |
| 100 Days | 100-day streak | "Built daily." |
| Never Missed Monday | 4 consecutive Mondays logged | "Mondays don't win." |
| Consistency > Motivation | 80%+ monthly consistency | "Showing up is the work." |

### Volume milestones
| Badge | Condition | Copy |
|-------|-----------|------|
| Tiny Gains | First workout logged | "Every rep counts." |
| 100 Reps | 100 total pushups | "A hundred done." |
| 1,000 Reps | 1,000 total pushups | "Four digits." |
| Iron Will | 1,000 total squats | "Legs of steel." |
| The Grind | 10,000 reps across all exercises | "The work adds up." |

### Behaviour milestones
| Badge | Condition | Copy |
|-------|-----------|------|
| Early Bird | Logged before 7 AM (5 times) | "Up before the world." |
| Night Owl | Logged after 10 PM (5 times) | "Fits wherever it fits." |
| Minimum Mode | Logged exactly 5 reps in a session | "Five was enough." |
| No Excuses | Logged on 3 different holidays | "Not an excuse." |
| Custom Builder | Added a custom exercise | "Made it yours." |

---

## Implementation notes

- Each achievement maps to a new `AchievementCondition` case in `Achievement.swift`
- `StreakViewModel.isEarned(_:)` evaluates all conditions against `allEntries`
- Newly earned achievements trigger a soft haptic + tab badge (no modal)
- Already-earned achievements persist to UserDefaults by ID

---

## Acceptance criteria

- [ ] All 20 achievements defined in `Achievement.swift`
- [ ] `isEarned` logic correct for each condition
- [ ] Tab badge appears when new achievement unlocked since last Streak view visit
- [ ] Achievement grid in `StreakView` scrolls gracefully with 20 items
- [ ] Achievements are retroactively evaluated on app launch
