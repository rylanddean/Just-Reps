# Friend Challenges

> Accountability without a social feed.

---

## Summary

A user can send a streak challenge to one friend via a shareable link. Both people see each other's streak count — nothing else. No feed, no likes, no public profiles. It ends after 30 days with a simple result: who showed up more.

---

## Why it fits the brand

The brand explicitly avoids influencer culture and social feeds. But accountability between two people — a friend group text, a partner, a sibling — is psychologically powerful and on-brand. The key constraint: this is private, bilateral, and time-boxed. It is not a social network.

---

## User story

> As someone trying to build a habit, I want to challenge my friend to a 30-day streak competition — so we both have someone to not let down.

---

## Design

### Sending a challenge
1. Tap "Challenge a friend" in Settings
2. App generates a unique link (e.g., `justreps.app/c/abc123`)
3. User shares via Messages, WhatsApp, etc.
4. Friend taps link → installs app (or opens it) → challenge activates

### Challenge view (new tab or modal)
```
┌─────────────────────────────┐
│  30-day challenge           │
│  Day 12 of 30               │
│                             │
│  You      🔥 11  ████████   │
│  Ryland   🔥  9  ███████    │
│                             │
│  14 days left               │
└─────────────────────────────┘
```
- Two names, two streak bars
- No rep counts visible to opponent — only streak day count
- Ends at 30 days; winner is shown, challenge archived

### End state
```
  Challenge complete.
  You: 27 days  |  Ryland: 24 days
  "Show up daily."
```
- No trophy animation, no leaderboard
- Archived in History for reference

---

## Technical notes

- **Backend required:** Firebase (or CloudKit public database) to store challenge state and sync streaks between two users
- **Auth:** Minimal — device-based anonymous ID sufficient; no email/password needed
- **Privacy:** Opponents only see streak day count, not exercise type or rep volume
- **Max active challenges:** 1 per user (keeps it focused)

---

## Acceptance criteria

- [ ] Challenge link generates and opens correctly
- [ ] Both users see real-time streak counts (within 5 minutes of logging)
- [ ] Challenge ends automatically at day 30
- [ ] Winner state displayed with on-brand copy
- [ ] No feed, no public profiles, no likes
- [ ] Challenge is opt-in, never surfaced unless user initiates
