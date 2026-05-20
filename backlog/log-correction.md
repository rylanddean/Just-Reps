# Log Correction

> Fix honest mistakes without judgment.

---

## Summary

Allow users to edit or delete a specific rep entry from the History view. Swipe-to-delete on a history row removes that entry. A future long-press option could allow editing the rep count. This is distinct from Integrity Mode (which prevents future retroactive logging) — this is about correcting genuine mistakes in past entries.

---

## Why it fits the brand

Just Reps is honest. If someone logged 100 reps when they meant 10, or double-tapped and logged a duplicate entry, the data is wrong. The brand calls for accurate records, not padded ones. A quiet, non-dramatic correction path — no confirmation dialog for delete, just a standard swipe — respects the user's intelligence and keeps the data trustworthy. Integrity Mode and Log Correction are two sides of the same coin: one prevents manipulation, the other fixes accidents.

---

## User story

> As someone who accidentally tapped +25 twice on a tired morning and logged 50 when I did 25, I want to fix that entry in History — so my rep count is accurate without having to delete the whole day.

---

## Design

### Delete (swipe-to-delete)

- **Gesture:** Standard leading or trailing swipe in `HistoryView` entry row
- **Confirmation:** None — swipe delete in iOS is already a deliberate gesture. The entry disappears immediately.
- **Undo:** System-level undo gesture (shake or `CMD+Z` on iPad) works for 3 seconds. No custom undo UI.
- **Effect:** Deletes the `WorkoutEntry` from SwiftData. Streak and heatmap recalculate on next render.
- **Streak impact:** If deleting the only entry for a given logical day, that day's heatmap cell goes dark and the streak recalculates. The app makes no comment on this.

### Edit rep count (stretch goal — V2 of this feature)

- **Trigger:** Long-press on a history entry row → context menu → "Edit reps"
- **UI:** A small sheet with a number pad pre-filled with current rep count
- **Saves:** On dismiss if count changed. No "Save" button — standard `.presentationDetents([.height(320)])` sheet that closes when the user taps outside or swipes down.

### Integrity Mode interaction

- If Integrity Mode is ON: swipe-to-delete is **not disabled** — deleting is not the same as adding fake reps. Correction is still allowed.
- The Integrity Mode setting prevents logging new reps to past days. It does not prevent deleting mistaken entries. These are different intentions.

### HistoryView implementation note

History uses `ScrollView` + `VStack` (not `List`), which means `.onDelete` is not available. Swipe-to-delete requires a custom swipe gesture or a `contextMenu` with a delete action. Prefer `.swipeActions` wrapping — wrap each row in a `ZStack` with swipe offset tracking, or restructure to use `List` with custom row styling if the complexity is too high.

---

## Acceptance criteria

- [ ] Each entry row in `HistoryView` supports swipe-to-delete
- [ ] Deleting an entry removes it from SwiftData immediately
- [ ] Heatmap and streak recalculate correctly after deletion
- [ ] Deleting the last entry for a day clears that day's heatmap cell
- [ ] No confirmation dialog for delete — gesture is confirmation enough
- [ ] Integrity Mode ON does not block deletion
- [ ] Undo works via system gesture for ~3 seconds after deletion

---

## What this is NOT

- Not a way to add entries for past days (that's the retroactive logging flow, blocked by Integrity Mode)
- Not a bulk-delete tool — one entry at a time
- Not a way to change the exercise type of an entry (wrong exercise? Delete and re-log today's entry)
- Not hidden behind Settings — it's a standard interaction in History
