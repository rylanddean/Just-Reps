# Share Streak Card

> The heatmap is satisfying to look at. Let people show it off.

---

## Summary

A shareable image card — generated on-device — showing the user's current streak, heatmap, and a tagline. One tap exports it to Photos or shares it directly. No social feed, no accounts required.

---

## Why it fits the brand

The brand's launch strategy is TikTok and Reddit. A polished share card is organic marketing that costs nothing. The content sells itself: a heatmap with one bright green cell at the end is a better ad than any copy.

---

## User story

> As someone with a 45-day streak, I want to share it with a friend without screenshotting the whole app UI — so I can show progress without looking like I'm showing off the app.

---

## Design

**Card layout (390×390pt square — optimised for Stories and posts):**

```
┌─────────────────────────────┐
│                             │
│   45                        │
│   DAY STREAK                │
│                             │
│   [heatmap — last 16 weeks] │
│                             │
│   just reps                 │
└─────────────────────────────┘
```

- Background: `#111111` (always dark, regardless of system theme)
- Streak number: large, heavy, `colorSuccessGreen`
- Heatmap: same component, smaller cells (8×8pt)
- Wordmark: lowercase `just reps` in caption weight, bottom-left
- No username, no social handle — the card is about the streak, not the person

**Trigger:** Share button in the toolbar on the Streak tab.

**Export:** Uses `ImageRenderer` (iOS 16+) to render the card off-screen, then `ShareLink` or `UIActivityViewController`.

---

## Acceptance criteria

- [ ] Share button appears in `StreakView` toolbar
- [ ] Card renders correctly at 1× and 2× (retina)
- [ ] Heatmap on card matches current `heatmapData`
- [ ] Export works to Photos, Messages, Instagram Stories
- [ ] Card always uses dark background regardless of device light/dark mode

---

## Copy options for the tagline

- "Show up daily." *(primary)*
- "Don't break the chain."
- "Built daily."
