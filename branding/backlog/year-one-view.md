# Year-One View

> You showed up. Here's the proof.

---

## Summary

After 365 days from first use, a single locked screen unlocks in the Streak tab: a full-year heatmap and one number — the days logged out of 365. Nothing else. No export prompt, no share sheet, no dashboard. It's a private moment, earned by time.

---

## Why it fits the brand

The brand celebrates consistency over performance. A year of data is the ultimate expression of that. Every analytics product would turn this into a dashboard with charts and PRs. Just Reps shows one number and the shape of your year — and then gets out of the way. The restraint *is* the feature.

---

## User story

> As someone who has been logging for over a year, I want to see the full picture of my consistency — not broken into weekly chunks but as one complete view — so I can appreciate the habit I've built.

---

## Design

- **Unlock condition:** App was first launched ≥ 365 days ago (stored as `firstLaunchDate` in UserDefaults).
- **Access:** A new section at the bottom of the Streak tab, revealed only after unlock. No teaser, no countdown. It either exists or it doesn't.
- **Layout:**

  ```
  [Full-year heatmap — 52 columns × 7 rows]

  312 of 365 days.
  ```

  The heatmap spans the full width of the screen. Week columns, Sunday–Saturday aligned, same cell style as the existing 20-week heatmap.

  Below it: one line of copy in `AppTheme.Typography.headline`, centered. Format: `"X of 365 days."` — no label, no percentage.

- **Colour:** Same `successGreen` intensity scale as the existing heatmap. No new visual language.
- **No share button.** No export. It's yours.
- **Static once rendered.** No animation on appearance. Just there.

---

## Acceptance criteria

- [ ] `firstLaunchDate` written to UserDefaults on first app launch (if not already set)
- [ ] Year-One section is invisible in Streak tab until `firstLaunchDate` is ≥ 365 days ago
- [ ] Full-year heatmap renders 52 week columns from `firstLaunchDate` forward
- [ ] "X of 365 days." copy calculated from `WorkoutEntry` count in that window
- [ ] No share, export, or social affordance
- [ ] Section does not appear in the Streak tab until the condition is met — no placeholder, no countdown

---

## What this is NOT

- Not a summary of volume, PRs, or total reps
- Not shareable from within the app
- Not a push notification or badge unlock — it just appears on next open
- Not shown until exactly 365 days have passed — no rounding, no early reveal
