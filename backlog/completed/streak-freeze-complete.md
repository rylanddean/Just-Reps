# Streak Freeze

> One missed day shouldn't erase weeks of discipline.

---

## Summary

A streak freeze lets users protect their streak on a single missed day. They earn one freeze token per 7-day perfect week. Using it is intentional — there's no automation, no guilt removal, just a safety net for real life.

---

## Why it fits the brand

The brand celebrates consistency, not perfection. A streak freeze is honest — it acknowledges that life happens — without rewarding laziness. The friction of manually activating it keeps it from being abused.

---

## User story

> As someone with a 30-day streak who had to travel yesterday and couldn't log, I want to protect my streak rather than restart from zero — so I don't abandon the habit entirely.

---

## Design

- **Earn:** 1 freeze token awarded automatically after any 7 consecutive logged days
- **Cap:** Max 2 tokens held at once (prevents stockpiling)
- **Activate:** Home screen shows a `🧊 Use Freeze` prompt the morning after a missed day (before the streak resets)
- **Visual:** Frozen days appear as a faint outline cell in the heatmap — distinct from an active day, honest about the gap
- **Copy:** "Life happens. Streak protected." — calm, not celebratory

## Acceptance criteria

- [ ] Token earned silently after 7-day streak (no popup)
- [ ] Prompt appears on home screen if yesterday was missed and token is available
- [ ] Activating freeze inserts a synthetic `WorkoutEntry` tagged `.freeze` for that day
- [ ] Heatmap renders freeze days with a different visual state
- [ ] Max 2 tokens enforced in `HomeViewModel`
- [ ] Token count persisted to UserDefaults

---

## What this is NOT

- Not an automatic undo
- Not something the app does for you
- Not a way to maintain a "fake" streak indefinitely
