# Integrity Mode

> What you logged is what you did.

---

## Summary

An opt-in setting that disables retroactive logging. When enabled, you can only log for today. The heatmap reflects exactly what was recorded in real time. No patching yesterday. No backdating a missed week.

---

## Why it fits the brand

Just Reps is a discipline app. Discipline means showing up, not managing records. Integrity Mode is for the user who takes the streak seriously enough to not want a back door — it removes the temptation to retroactively "fix" a missed day and makes the heatmap a true record. No other fitness app has a setting that deliberately reduces what you can do.

---

## User story

> As someone who cares about having an honest streak, I want to lock out retroactive logging — so my heatmap reflects what I actually did, not what I wish I had done.

---

## Design

- **Location:** Settings → (exercise/goal section or a standalone row near the bottom). Label: `"Integrity Mode"`. Sub-label: `"Disable logging for past days."`
- **Toggle:** Standard SwiftUI `Toggle`. Off by default.
- **Effect:** When on, the `+` buttons on exercise cards are disabled for any date other than today. History view loses the ability to add entries for past days.
- **No warning on enable.** It's not destructive — it doesn't delete anything. Just tap to turn on.
- **Confirmation on disable** (one-time): `"Turn off Integrity Mode?"` — because turning it off opens the back door. A single `confirmationDialog` is appropriate here.
- **Heatmap:** No visual distinction between Integrity Mode days and regular days. The mode is about behaviour, not display.

---

## Acceptance criteria

- [ ] `integrityMode: Bool` persisted to UserDefaults, default `false`
- [ ] When enabled, rep-logging controls are inert for any date other than `StreakEngine.logicalDay(for: .now)`
- [ ] History view "add entry" affordance is hidden or disabled when Integrity Mode is on
- [ ] Disabling Integrity Mode shows a single `confirmationDialog` — not on enable
- [ ] No impact on streak calculation, heatmap rendering, or existing entries

---

## What this is NOT

- Not a way to delete or hide past entries
- Not enforced by the app — it's a personal commitment setting, not parental controls
- Not visible anywhere in the UI except Settings
- Not the default — most users don't need it
