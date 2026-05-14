# Custom Themes

> The app should feel like yours.

---

## Summary

A small set of premium colour themes — 4 to 6 options — that change the accent colour across the app. Not a full skin system. The structure, typography, and layout never change. Only the green.

---

## Why it fits the brand

The brand is minimal and modern. Themes are a natural premium unlock because they're purely cosmetic, deeply personal, and have zero impact on functionality. They reward long-term users without changing the product.

---

## Theme proposals

| Name | Accent | Mood |
|------|--------|------|
| Default | `#5FD38D` (Success Green) | Calm, natural |
| Midnight | `#6BA8FF` (Cool Blue) | Focused, cool |
| Ember | `#FF8C5A` | Warm, driven |
| Chalk | `#E8E8E4` | Quiet, minimal |
| Carbon | `#888888` | Stoic, grey |
| Gold | `#F0C040` | Earned, warm |

All themes use the same background (`#000000` / `#111111` dark, `#F7F7F5` light). Only the accent colour changes.

---

## Design rules

- **One accent swap.** `colorSuccessGreen` is the only token that changes. Every other colour token stays constant.
- **No custom fonts.** SF Pro only. Typography is not a theme variable.
- **No backgrounds.** The dark/light mode toggle handles background. Themes don't change it.
- **Preview before buying.** Users see a live preview in the theme picker before unlocking.

---

## UX flow

1. Settings → Appearance → Theme
2. Horizontal scroll of theme cards (showing the ring progress bar in each accent)
3. Free themes: Default only
4. Premium themes: blurred with a lock icon → one-tap StoreKit purchase
5. Selected theme applies immediately via `AppTheme.Colors.accent` (dynamic)

---

## Technical notes

- `AppTheme.Colors.successGreen` becomes a computed property that reads from a `@AppStorage("selectedTheme")` key
- `AppTheme.Colors.coolBlue` (goal streak colour) shifts proportionally with the accent
- StoreKit 2 non-consumable IAP per theme, or single "Premium" unlock

---

## Acceptance criteria

- [ ] 6 themes defined in `AppTheme`
- [ ] Theme selection persists across app launches
- [ ] All ring components, progress bars, and streak counters respect the active theme
- [ ] Theme picker shows live preview
- [ ] Premium themes gated behind StoreKit purchase
- [ ] Default theme always free
