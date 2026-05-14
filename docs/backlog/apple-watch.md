# Apple Watch App

> Log a set without touching your phone.

---

## Summary

A minimal watchOS companion app. One screen: today's exercises with rep counts and a single large tap target per exercise. Syncs with the iPhone app via WatchConnectivity. No independent streak calculation — the Watch is a logging terminal, the phone is the source of truth.

---

## Why it fits the brand

The brand is about removing friction. Logging from your wrist during a workout — without unlocking your phone — is the lowest-friction version of the product. The Watch app must be *even simpler* than the phone app.

---

## Screens

### Complication
- Shows current streak (number)
- Deep-links into the Watch app

### Main screen (only screen)
```
┌────────────────────┐
│  💪 Pushups        │
│  12 / 25           │
│  [  + 10  ]        │
│                    │
│  🦵 Squats         │
│   8 / 50           │
│  [  + 10  ]        │
└────────────────────┘
```
- One card per active exercise (scrollable)
- Large `+10` button — Digital Crown adjustable for custom amount
- Logs immediately; syncs to iPhone in background

### Completion
- Gentle Taptic Engine tap
- "Done. Go live your life." — 2 seconds, then auto-dismisses

---

## Technical notes

- **Target:** New `JustRepsWatch` WatchKit App target
- **Sync:** `WCSession` sends logged reps as `WorkoutEntry` JSON to the iPhone; iPhone inserts into SwiftData
- **Offline:** Watch queues entries when phone is out of range; flushes on reconnect
- **Complication:** `CLKComplicationDataSource` with `CLKSimpleTextProvider` for streak count
- **watchOS minimum:** 10.0

---

## Acceptance criteria

- [ ] Watch app shows current active exercises from phone settings
- [ ] Tapping `+10` logs immediately (optimistic UI) and syncs to iPhone
- [ ] Digital Crown adjusts custom rep amount
- [ ] Offline queue flushes within 30 seconds of phone connection
- [ ] Streak complication updates daily
- [ ] Completion haptic fires when all goals met
- [ ] No independent streak calculation on Watch — always defers to phone data
