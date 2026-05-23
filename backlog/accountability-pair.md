# Accountability Pair

> One person. One shared thread. Nothing more.

---

## Summary

Connect with a single accountability partner. They see your daily streak status — logged or not yet logged — and nothing else. No rep counts. No exercise names. No comments. No reactions. You see theirs. The connection is deliberately shallow: its value is that the other person knows you showed up today, and you know they know.

---

## Why it fits the brand

The research is consistent: opt-in, private accountability increases long-term retention significantly — and social pressure without privacy destroys it. Every social fitness feature in the market overshoots. Leaderboards create anxiety. Challenges create obligation. Comment feeds create performance. Accountability Pair strips all of that out and leaves the one thing that actually works: a trusted person, quietly paying attention.

This is the only social feature Just Reps will ever have, and it should feel like it belongs to a different category than what fitness apps normally do with social. No feeds. No prompts. No engagement mechanics.

---

## User story

> As someone who tends to skip when no one is watching, I want my partner to know whether I showed up today — so I have a reason to do it that isn't about numbers or streaks, just not letting them down.

---

## Design

### Pairing

**Sending an invite:**
- Settings → "Accountability partner" → `"Invite someone"` button
- Generates a short-lived (48h) invite link: `justreps://pair?token=ABC123`
- User shares the link via the system share sheet — iMessage, WhatsApp, email, anything
- The link resolves to a lightweight backend endpoint that stores the pairing token

**Accepting an invite:**
- Recipient opens the link on iOS; deep link opens Just Reps (or App Store if not installed)
- Just Reps shows a single sheet: `"[Name] wants to be your accountability partner. They'll see whether you've logged today. Nothing else."` — two buttons: `"Pair up"` and `"Not now"`
- On acceptance, the pairing is established. Both parties see each other's status going forward.

**Pairing limit:** Exactly one accountability partner per user. Changing partners requires unpairing first.

### Status display

**Location:** A new card at the bottom of `StreakView`, below the heatmap.

```
┌─────────────────────────────────┐
│  Jordan                         │
│  Day 23 — logged today          │
└─────────────────────────────────┘
```

- **Name:** Display name pulled from their device at pair time (stored server-side)
- **Status:** Two states only:
  - `"Day [N] — logged today"` — in `successGreen`
  - `"Day [N] — not yet"` — in secondary label colour
- **No tap target.** The card is read-only. No profile, no details, no drill-down.
- **No "nudge" button.** The app does not facilitate messaging. If a user wants to check in, they open their actual messaging app.

**Their view of you:**

```
┌─────────────────────────────────┐
│  You                            │
│  Day 47 — logged today          │
└─────────────────────────────────┘
```

Your own status card appears above your partner's in your Streak tab. You see what they see.

### Privacy model

What the partner sees:
- ✅ Whether you logged today (yes / not yet)
- ✅ Your current streak length
- ❌ Number of reps
- ❌ Which exercises you do
- ❌ Your goals
- ❌ Your history

What the app stores server-side:
- Pairing tokens
- Daily logged/not-logged status per user (updated once per day, on first rep of the day)
- Display names (set at pair time, not synced from Contacts or Apple ID)
- No biometric data, no exercise data, no rep counts

### Backend requirements

- Lightweight pairing server (token generation, status push)
- Status updates: when user logs their first rep of the day, a background push is sent to their partner's device
- Silent push notification updates the partner's status card without a visible notification

### Unpairing

- Settings → "Accountability partner" → `"Remove [Name]"`
- Confirmation sheet: `"Remove [Name] as your accountability partner? They won't see your status after this."`
- Unpairing is immediate. The other party sees their status card disappear on next app open.

---

## Acceptance criteria

- [ ] Settings row "Accountability partner" shows current partner or "Invite someone" if unpaired
- [ ] Invite generates a 48h-valid deep link; opens share sheet
- [ ] Recipient sees a pairing sheet with one-tap accept/decline
- [ ] Pairing stores only: display name, daily logged status, streak length
- [ ] Status card appears in `StreakView` below heatmap — two states: logged / not yet
- [ ] Your own status card appears above your partner's (you see what they see)
- [ ] Partner status updates via silent push on first rep of the day
- [ ] No rep counts, exercise names, or goals are shared
- [ ] No nudge, comment, or reaction affordance exists
- [ ] Unpairing is immediate; partner's card disappears on their next app open
- [ ] Maximum one active partner per user
- [ ] If partner uninstalls or unregisters, card shows `"[Name] — no data"` and Settings prompts to remove

---

## What this is NOT

- Not a leaderboard — there is no ranking, no comparison of streaks
- Not a challenge — no shared goals, no competitive mechanic
- Not a messaging feature — no in-app chat, nudges, or comments
- Not open to groups — exactly one partner, by design
- Not public — the pairing is private and visible to no one else
- Not a social feed — there is no activity stream, no likes, no notifications about the partner beyond status updates
- Not a V1 feature — requires backend infrastructure; planned for V2
