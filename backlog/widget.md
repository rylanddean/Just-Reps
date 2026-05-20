# Home Screen Widget

> The streak should be visible without opening the app.

---

## Summary

Two widget sizes — small and medium — showing the current streak and a mini heatmap. Tapping the widget deep-links directly into the logging screen. Built with WidgetKit; data shared via App Group.

---

## Why it fits the brand

The brand's core principle is zero friction. If the streak is on the home screen, the user sees it every time they pick up their phone. That ambient reminder is more powerful than any push notification.

---

## Widget variants

### Small (2×2)
```
┌──────────────┐
│   🔥 14      │
│   day streak │
│              │
│   Show up.   │
└──────────────┘
```
- Streak count, large and green
- Tagline rotates from the brand copy set
- Taps → home screen, logging view

### Medium (4×2)
```
┌─────────────────────────────┐
│  🔥 14 day streak           │
│                             │
│  [mini heatmap — 8 weeks]   │
└─────────────────────────────┘
```
- Left column: streak count
- Right: compressed 8-week heatmap
- Taps → home screen

### Lock Screen (inline)
```
🔥 14-day streak
```
- Single line, system font
- WidgetKit `accessoryInline` family

---

## Technical notes

- **Data sharing:** `WorkoutEntry` data and streak count written to a shared `AppGroup` UserDefaults container on every `logReps` call in `HomeViewModel`
- **Widget timeline:** Refreshes at midnight (streak day rollover) and after each rep log via `WidgetCenter.shared.reloadAllTimelines()`
- **Target:** New `JustRepsWidget` target in the existing Xcode project
- **Minimum iOS:** 16.0 (WidgetKit lock screen families require iOS 16)

---

## Acceptance criteria

- [ ] Small widget shows correct streak count
- [ ] Medium widget shows correct heatmap (last 8 weeks)
- [ ] Lock screen inline widget works on iOS 16+
- [ ] Streak updates within 1 minute of logging reps
- [ ] Tapping any widget opens the Today tab
- [ ] Widget renders correctly in light and dark mode
- [ ] Widget placeholder state shows "—" streak (not 0)
