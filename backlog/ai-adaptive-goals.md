# AI Adaptive Goals

> Goals that grow with you — without you having to think about it.

---

## Summary

Weekly, the app analyses the user's logged volume and quietly suggests adjusted daily goals. The suggestion is a single number — no explanation required, no settings screen. The user taps "Update" or ignores it.

---

## Why it fits the brand

Manual goal-setting requires discipline the user might not have yet. Adaptive goals remove that decision entirely. The brand is about lowering barriers — this is the logical extension of that for long-term users.

The tone must be calm and encouraging, never "you're not doing enough."

---

## How it works

**Weekly trigger:** Every Sunday evening, if the user has 4+ logged days that week, the engine evaluates each exercise.

**Adjustment logic (on-device, no API required for V1):**

```
if avgDailyReps > goal * 1.2:
    suggest goal * 1.15  // "you're comfortably over, nudge up"
elif avgDailyReps < goal * 0.6:
    suggest goal * 0.85  // "you're struggling, ease back"
else:
    no suggestion         // goal is well-calibrated
```

Adjustments capped at ±25% per week to prevent runaway scaling.

**V2 (Claude API):** Send 4-week volume history to Claude claude-opus-4 with a system prompt defining the brand tone. Claude returns a one-sentence suggestion and a goal number. This enables contextual messages like: *"You've been crushing squats. Try 60 this week?"*

---

## UX

**Suggestion card** (appears on home screen, Sunday evening):

```
┌─────────────────────────────┐
│  New goal suggestion        │
│                             │
│  Pushups  25 → 30           │
│  Squats   50 → 55           │
│                             │
│  [Update]    [Keep current] │
└─────────────────────────────┘
```

- Non-intrusive: appears below the exercise cards, not as a modal
- Tapping "Update" applies goals immediately, no confirmation
- Tapping "Keep current" dismisses for the week
- No explanation of why — the number speaks for itself

---

## Copy principles

- Never: "You're falling short of your goal."
- Always: "Here's a goal that fits your week."
- Downward adjustments framed as recalibration, not failure: *"Ease into it."*

---

## Acceptance criteria

- [ ] Suggestion computed on-device from `WorkoutEntry` history
- [ ] Fires at most once per week, on Sunday evening
- [ ] User can accept or dismiss without penalty
- [ ] Dismissed suggestion does not reappear until next Sunday
- [ ] Adjustments capped at ±25% per evaluation
- [ ] No suggestion shown with fewer than 4 days of data that week
- [ ] (V2) Claude API integration with fallback to on-device logic if offline
