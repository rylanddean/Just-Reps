# Streak Eulogy

> It happened. It was real.

---

## Summary

The first time the user opens the app after breaking a streak, a simple bottom sheet appears: the streak length, one line of copy, and a single dismiss button. No re-engagement prompt, no tips, no recovery offer. Acknowledged, then gone.

---

## Why it fits the brand

Every other app either ignores streak loss or makes it dramatic. Just Reps is the only app that could treat it with quiet dignity — a moment of acknowledgment before moving on. This is "never shame" made structural.

---

## Scenario

Someone built a 23-day streak. Life got in the way. They come back to the app expecting nothing, and instead get a single, honest acknowledgment of what they built — not a lecture, not a guilt trip. They close the sheet and start again.

---

## Design

- **Trigger:** Sheet appears once, on first launch after a streak of ≥ 7 days breaks. Streaks under 7 days don't warrant ceremony.
- **Content:**

  ```
  23 days.
  That's real.
  ```

  The broken streak count. One line of copy. Nothing else.

- **Dismiss button:** `"Start again"` — not "OK", not "Let's go". Plain text, full-width pill.
- **No second sheet.** The eulogy won't fire again until the user rebuilds a streak of ≥ 7 days and breaks it again.
- **Copy by streak length:**

  | Length | Copy |
  |--------|------|
  | 7–29 days | "That's real." |
  | 30–89 days | "That's real progress." |
  | 90+ days | "That's discipline." |

- **No share prompt.** No "tell a friend." It's a private moment.

---

## Acceptance criteria

- [ ] Sheet fires once on first launch after a streak ≥ 7 days ends
- [ ] Displays the broken streak count and appropriate copy line
- [ ] Dismiss button reads "Start again" and closes the sheet
- [ ] Sheet does not fire again until the user rebuilds and breaks another streak ≥ 7 days
- [ ] Shown state persisted to UserDefaults keyed to the broken streak length
- [ ] Sheet does not appear if the streak ended via Streak Freeze

---

## What this is not

- An offer to freeze or undo the streak
- A recovery tip or "here's what to try next time"
- Shown for streaks under 7 days
- Shareable from within the sheet
