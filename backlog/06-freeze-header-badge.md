# Refactor: Freeze token as streak-header badge (remove freeze prompt card)

**Status:** Ready  
**Effort:** S  
**Risk:** Low

## Problem

`freezePromptCard` is a full-width card that appears between the state message and the exercise cards when `shouldShowFreezePrompt` is true. It visually weighs as much as an exercise card and interrupts the home screen layout. The `Use` button is also immediately actionable with no confirmation — easy to trigger accidentally.

## Change

Remove `freezePromptCard` from `HomeView`.

When `shouldShowFreezePrompt` is true, the REP STREAK cell in `HeaderCardView` shows a small accessory below the streak number:

```
  [ 🧊 ]
```

A small `🧊` capsule badge (with `AppTheme.Colors.coolBlue` background, caption text) below the streak number. Making the whole REP STREAK cell (or the badge itself) tappable opens a confirmation sheet:

```
Use a freeze?
Life happens. Streak protected.

[Use Freeze]   [Cancel]
```

Sheet uses `.presentationDetents([.height(220)])`.

`useFreeze(context:)` is called on confirm, sheet dismisses.

## API changes

`HeaderCardView` needs:
- `shouldShowFreezePrompt: Bool`
- `onUseFreezeRequested: () -> Void` callback (or a `@Binding var showFreezeSheet: Bool` lifted to HomeView)

The simplest approach: lift freeze sheet state to `HomeView`, pass `shouldShowFreezePrompt` as a display flag to `HeaderCardView`, handle sheet in `HomeView`.

## Files

- `Just Reps/Views/HomeView.swift` — remove `freezePromptCard`, add freeze sheet
- `Just Reps/Components/HeaderCardView.swift` — add freeze badge to REP STREAK cell

## Acceptance

- No freeze prompt card in the home scroll area
- When freeze is available + yesterday missed: `🧊` badge visible on REP STREAK cell
- Tapping badge opens confirmation sheet
- `Use Freeze` calls `viewModel.useFreeze`, badge disappears
- `Cancel` dismisses without action
- No freeze available: no badge, no sheet
