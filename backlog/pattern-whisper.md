# Pattern Whisper

> One thing that's true about you, quietly.

---

## Summary

Once a week, a single on-device-generated sentence appears at the bottom of the Streak tab. It observes something specific and true about the user's recent logging pattern — when they log, which days, which exercises. No chart, no percentage, no action required. It disappears after 24 hours or once seen. It never tells the user what to do.

---

## Why it fits the brand

The brand celebrates consistency without turning it into a performance review. Pattern Whisper is the on-device equivalent of a friend who's been paying attention: "You tend to log right after waking up." That's not advice. It's a quiet mirror — a reflection of a habit the user has already built without realising it. Using FoundationModels keeps it fully private. The observation is generated fresh each week from real data, so it only appears when there's something specific to say.

This is distinct from Month Recap (which is a factual count) and Advanced Analytics (which is a premium dashboard). Pattern Whisper is one line, free, and ephemeral.

---

## User story

> As someone two months into a streak, I want a quiet acknowledgment that the app sees my pattern — not a chart, not a score, just something true — so I feel witnessed without being evaluated.

---

## Apple Intelligence technical approach

**Framework:** `FoundationModels` (iOS 18.1+)

**Generation trigger:**
- Every Monday, if the user has ≥ 14 logged days in the last 30 days
- Only one whisper per week — once generated, no new one until next Monday
- Stored in UserDefaults: `lastWhisperDate` and `lastWhisperText`

**Input to the model:**

```swift
struct WhisperContext: Codable {
    let recentDays: [String: [String]]   // date → [exercise logged]
    let typicalLogHour: Int              // median hour of recent entries
    let strongestDayOfWeek: String       // e.g. "Monday"
    let weakestDayOfWeek: String         // e.g. "Saturday"
    let daysSinceFirstEntry: Int         // app tenure
    let currentStreakLength: Int
}
```

**System prompt:**

> You write one short, specific, factual observation about a person's fitness logging pattern. You have their recent data. Observe one concrete truth. Do not give advice. Do not use exclamation points. Do not say "great," "amazing," or "impressive." Maximum 12 words. Output only the observation, nothing else.

**Output schema:**

```swift
@Generable
struct Whisper {
    var observation: String   // e.g. "You tend to log before 8AM."
}
```

**Generation timing:** Background task on Monday morning. Generated observation is cached in UserDefaults and displayed when the user opens the Streak tab that week.

**Fallback:** If Apple Intelligence is unavailable, no whisper appears. No empty state, no placeholder. The section simply doesn't exist on unsupported devices.

---

## Design

```
────────────────────────────────────

  You tend to log before 8AM.

────────────────────────────────────
```

- **Position:** Below the heatmap in `StreakView`, above any other content sections
- **Typography:** `AppTheme.Typography.body` in `Color(UIColor.secondaryLabel)` — quiet, clearly secondary
- **No label** — no "Insight" heading, no AI badge, no icon. Just the line.
- **Dismiss:** Tapping anywhere on the line marks it as seen (`UserDefaults`). Fades out with 0.2s opacity. No explicit dismiss button.
- **Auto-expiry:** If not dismissed, disappears after 24h. `lastWhisperDate` is checked on each `StreakView` appear.
- **No indicator that it's AI-generated.** It's just a quiet observation.

---

## Example whispers (target range)

- "You tend to log before 8AM."
- "Weekends are harder for you. You still show up."
- "Push-ups every day. Squats, almost."
- "You've never missed a Monday in six weeks."
- "Most of your sessions happen within the same hour."
- "You're more consistent in the morning than the evening."

---

## Gating conditions

| Condition | Behaviour |
|-----------|-----------|
| Apple Intelligence not available | Whisper section does not exist — no fallback text |
| Fewer than 14 logged days in last 30 | No whisper generated this week |
| First 2 weeks of app use | No whisper generated |
| Model fails or times out | No whisper this week — silent skip |
| Whisper already shown this week | Not regenerated until next Monday |

---

## Acceptance criteria

- [ ] `FoundationModels` used for generation; no network calls
- [ ] Generated once per week (Monday), cached in UserDefaults
- [ ] Requires ≥ 14 logged days in last 30 days before generating
- [ ] Appears below heatmap in `StreakView`, using `secondaryLabel` colour
- [ ] Tapping dismisses with 0.2s fade; `UserDefaults` records dismissal
- [ ] Auto-expires after 24h if not tapped
- [ ] Section is completely absent on unsupported devices
- [ ] No "AI-generated" label or indicator in the UI

---

## What this is NOT

- Not advice — never tells the user what to do or change
- Not a notification — discovered only by opening the Streak tab
- Not persistent — one glimpse and it's gone
- Not a dashboard — one line, not a list of stats
- Not shown in the first two weeks (insufficient data to observe anything true)
