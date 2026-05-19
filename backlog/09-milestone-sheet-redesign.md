# Polish: CreateMilestoneSheet visual redesign

**Status:** Ready  
**Effort:** M  
**Risk:** None — view-only, no data model changes

## Problem

`CreateMilestoneSheet` is the only view in the app that uses a grouped `Form` with standard iOS table section styling. It looks like a Settings screen inside a minimal dark UI. The visual language (separator lines, indented rows, grouped sections) clashes with every other surface in the app.

## Change

Replace the `Form` body with a `ScrollView` + `VStack` of custom card rows using `secondarySystemBackground` and `AppTheme.Radius.card`.

### New layout

```
[ Name                         ]  ← text field in a card
[ Metric  [Rep Streak] [Goal Streak] [Total Reps] ]  ← segmented in a card
[ Exercise  Pushups ▾ ]  ← shown only for Total Reps, in same card as Metric
[ Target  -  30  +  days ]  ← card with inline stepper
```

Each section is a card (same background/radius as milestone cards in StreakView). Labels use `AppTheme.Font.caption()` with kerning for section titles, same pattern as the rest of the app. No section footers.

The `Save` / `Cancel` toolbar buttons can stay as-is — they're standard and correct for a sheet.

### Segmented control

Keep `Picker` with `.pickerStyle(.segmented)` — it fits well inside a card with `md` padding. Remove `.listRowInsets` modifier (no longer needed).

### Stepper row

```swift
HStack {
    Button { target = max(1, target - targetStep) } label: {
        Image(systemName: "minus")
            .frame(width: 32, height: 32)
            .background(Color(UIColor.tertiarySystemBackground), in: Circle())
    }
    .buttonStyle(.plain)
    
    Text("\(target)")
        .font(.system(size: 28, weight: .heavy, design: .rounded))
        .frame(minWidth: 60, alignment: .center)
    
    Button { target = min(9999, target + targetStep) } label: {
        Image(systemName: "plus")
            .frame(width: 32, height: 32)
            .background(Color(UIColor.tertiarySystemBackground), in: Circle())
    }
    .buttonStyle(.plain)
    
    Text(targetUnit)
        .font(AppTheme.Font.caption())
        .foregroundStyle(.secondary)
}
.frame(maxWidth: .infinity)
```

Remove the `TextField` for target (stepper-only is cleaner; range is 1–9999 with step 7 or 50).

## Files

- `Just Reps/Views/StreakView.swift` (the `CreateMilestoneSheet` private struct lives here)

## Acceptance

- No `Form` or grouped table sections visible
- All fields use card backgrounds with `AppTheme.Radius.card`
- Typography matches the rest of the app
- Save/Cancel still work correctly
- All three metric types (Rep Streak, Goal Streak, Total Reps) still render correctly
