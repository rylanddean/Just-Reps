# Streak Eulogy

> It happened. It was real.

---

## Summary

The first time the user opens the app after breaking a streak, a simple bottom sheet appears: the streak length, one line of copy, and a single dismiss button. No re-engagement prompt, no tips, no recovery offer. Acknowledged, then done.

---

## Why it fits the brand

Every other app either ignores streak loss or makes it dramatic. Just Reps is the only app that could treat it with quiet dignity — a moment of acknowledgment before moving on. This is "never shame" made structural.

---

## User story

> As someone who broke a 23-day streak, I want the app to acknowledge what I built — not lecture me about losing it — so I feel motivated to start again rather than embarrassed.

---

## Design

- **Trigger:** Sheet appears once, on first launch after a streak of ≥ 7 days breaks. Not for streaks under 7 — too short to warrant ceremony.
- **Content:**

  ```
  23 days.
  That's real.
  ```

  One line with the streak count. One line of copy (fixed). Nothing else.

- **Dismiss button:** `"Start again"` — not "OK", not "Let's go", not an emoji. Plain text, full-width pill.
- **No second sheet.** If they break another streak the next day, no eulogy fires until they've rebuilt ≥ 7 days again.
- **Copy variations by streak length:**

  | Length | Copy |
  |--------|------|
  | 7–29 days | "That's real." |
  | 30–89 days | "That's a real habit." |
  | 90+ days | "That's discipline." |

- **No share prompt.** No "tell a friend." It's a private moment.

---

## Acceptance criteria

- [ ] Sheet fires once on first launch after a streak ≥ 7 days ends
- [ ] Displays the broken streak count and appropriate copy line
- [ ] Dismiss button reads "Start again" and closes the sheet
- [ ] Sheet does not fire again until the user rebuilds and breaks another streak ≥ 7 days
- [ ] "Shown" state persisted to UserDefaults with the broken streak length
- [ ] Sheet does not appear if the streak ended via Streak Freeze (not a real break)

---

## What this is NOT

- Not an offer to freeze or undo the streak
- Not a recovery tip or "here's what to try next time"
- Not shown for streaks under 7 days
- Not shareable from within the sheet
