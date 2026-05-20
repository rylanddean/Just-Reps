# Lock Screen Widget

> Today's progress without unlocking your phone.

---

## Summary

A lock screen accessory widget showing today's logging state at a glance. Two variants: a circular widget (one exercise, rep count vs goal) and an inline widget (a row of exercise status dots — filled if logged, empty if not). Both update in real time when reps are logged. No interaction required — it's read-only.

---

## Why it fits the brand

The home screen widget was a V2 priority because the app's daily interaction is so brief — a lock screen widget extends that ambient presence without demanding time or attention. The user glances at their phone, sees three green dots, puts it away. The app has done its job without them ever opening it. That's the "now go live your life" ethos working at the OS level.

---

## User story

> As someone trying to remember to log before bed, I want to glance at my lock screen and see whether I've done today's exercises — so I don't need to open the app just to check.

---

## Design

### Circular variant (`.accessoryCircular`)

```
  ┌──────┐
  │  47  │
  │ reps │
  └──────┘
```

- Shows total reps logged today across all exercises
- Fill ring: progress toward combined daily goal (successGreen)
- Tapping opens Just Reps to `HomeView`

### Inline variant (`.accessoryInline`)

```
  ● ● ○  Just Reps
```

- One filled/empty dot per active exercise
- Filled (●) = at least 1 rep logged today
- Empty (○) = zero reps
- Text suffix: "Just Reps"
- Tapping opens Just Reps to `HomeView`

### Rectangular variant (`.accessoryRectangular`) — optional stretch goal

```
  Just Reps
  Push-ups ████░░ 25
  Squats   ██████ 30 ✓
```

A mini version of the exercise card list with progress bars.

### Widget entry timeline

Same `WidgetKit` `Provider` as the home screen widget. Entries refresh on:
- Each rep logged (via App Intent or `WidgetCenter.shared.reloadAllTimelines()`)
- 3AM logical day boundary

### Design constraints

- Lock screen widgets are monochromatic in certain contexts (watchOS-style). Use system foreground colours — don't rely on `successGreen` for meaning, use fill level instead.
- Inline widget: 5 characters max for the text portion. Dots must come first.

---

## Acceptance criteria

- [ ] `.accessoryCircular` widget shows total reps today and a progress ring
- [ ] `.accessoryInline` widget shows one dot per active exercise (filled = logged)
- [ ] Both widgets tap through to `HomeView`
- [ ] Widgets refresh within 60 seconds of a rep being logged
- [ ] Widgets correctly use logical day (3AM boundary), not calendar midnight
- [ ] Widgets render correctly in monochromatic lock screen mode
- [ ] Widgets appear in the lock screen widget picker under "Just Reps"

---

## What this is NOT

- Not interactive — lock screen widgets cannot log reps (iOS restriction)
- Not a replacement for the home screen widget — complementary, different sizes
- Not a notification — purely ambient, never demands attention
- Not shown on the watch face (that's the complication)
