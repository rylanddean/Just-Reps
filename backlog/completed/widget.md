# Home Screen Widget

> The streak should be visible without opening the app.

---

## Summary

Three widget surfaces — small, medium, and lock screen inline — showing the current streak and (in the medium) a mini heatmap. Tapping any widget deep-links directly to the Today tab. Built with WidgetKit; data shared via the existing App Group (`group.com.rylanddean.justreps`).

---

## Why it fits the brand

Zero friction means the streak is always visible. Seeing it on the home screen every time the user picks up their phone is a quieter, calmer reminder than any push notification.

---

## Widget variants

### Small (systemSmall)

```
┌──────────────┐
│  REP STREAK  │
│     14       │  ← large, successGreen; streakDanger if at-risk
│    days      │
│              │
│ Just do      │
│ the reps.    │
└──────────────┘
```

- Streak count, large and colored per state (see States below)
- Fixed tagline: "Just do the reps." — no rotation, no extra variables
- Taps → Today tab

### Medium (systemMedium)

```
┌────────────────────────────────────┐
│  REP STREAK  │  GOAL STREAK        │
│     14       │      7              │
│    days      │    days             │  ← dual streak mirrors app header
├──────────────┴─────────────────────┤
│  [8-week heatmap — dot grid]       │
└────────────────────────────────────┘
```

- Top half: dual streak cells separated by a 0.5pt vertical divider — matches HomeView header exactly
- Bottom half: 8-week dot-grid heatmap (successGreen dots for logged days)
- Taps → Today tab

### Lock Screen (accessoryInline)

```
14 day streak
```

- Plain text, no emoji — one line, system font
- WidgetKit `accessoryInline` family
- Reads rep streak only (inline label is too narrow for both)

---

## Streak states

| State | Condition | Color |
|-------|-----------|-------|
| Active | streak > 0, logged today | `successGreen` |
| Pending | streak > 0, not yet logged | `successGreen` (preserve positive state until at-risk) |
| At-risk | streak > 0, after 8 PM, nothing logged | `streakDanger` |
| Zero | streak == 0 | `.secondary` (gray) |

The timeline provider generates two entries if it's before 8 PM: one for now and one for 8 PM (the at-risk flip). This avoids the widget staying green all night.

---

## Technical notes

- **App Group:** `group.com.rylanddean.justreps` (already in use)
- **Keys written by HomeViewModel.refresh():**
  - `currentRepStreak` — `Int` (already written)
  - `currentGoalsStreak` — `Int` (new)
  - `widgetHeatmap` — JSON `[String: Bool]` keyed `"YYYY-MM-DD"`, last 56 days (new)
- **Timeline reload:** `WidgetCenter.shared.reloadAllTimelines()` called at the end of `HomeViewModel.refresh()` (new)
- **Timeline policy:** next midnight (streak day rollover). If before 8 PM, also emit a second entry at 8 PM to flip to at-risk color.
- **Deep link:** `justreps://today` URL scheme; `ContentView` switches to the Today tab on receipt
- **Minimum iOS:** 16.0 (lock screen widget families require iOS 16; app already targets iOS 17 so this is a non-issue)
- **Widget target:** `JustRepsWidget` — new Xcode target. Files live in `JustReps/JustRepsWidget/`.

---

## Acceptance criteria

- [ ] Small widget shows correct rep streak count
- [ ] Small widget shows "Just do the reps." tagline
- [ ] Small widget turns `streakDanger` after 8 PM with no reps logged
- [ ] Medium widget shows both rep streak and goal streak
- [ ] Medium widget heatmap reflects last 8 weeks of activity
- [ ] Lock screen inline shows plain-text streak count
- [ ] Widget updates within 1 minute of logging reps
- [ ] Tapping any widget opens the Today tab
- [ ] Widget renders correctly in light and dark mode
- [ ] Placeholder state shows "—" streak (not 0)
