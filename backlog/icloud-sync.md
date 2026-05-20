# iCloud Sync

> Your streak should survive a new phone.

---

## Summary

Sync `WorkoutEntry` data across the user's devices via CloudKit (SwiftData's built-in cloud backend). No account creation, no password — it just works if the user is signed into iCloud. Data is private to that Apple ID.

---

## Why it fits the brand

The brand promises discipline without friction. Losing a 60-day streak because you switched phones is a trust-breaking moment. iCloud sync prevents that silently, with zero setup from the user.

---

## Why iCloud over Firebase

Firebase requires an account, email, and password flow — friction that contradicts the brand's core principle. iCloud requires nothing extra from a user already signed into their iPhone.

---

## Technical approach

SwiftData supports CloudKit sync via a single change to the `ModelContainer` initialisation:

```swift
// Current
.modelContainer(for: WorkoutEntry.self)

// With iCloud sync
let config = ModelConfiguration(cloudKitDatabase: .automatic)
.modelContainer(for: WorkoutEntry.self, configurations: config)
```

CloudKit handles conflict resolution automatically using last-write-wins with timestamp ordering — appropriate for append-only workout logs.

**Requirements:**
- iCloud capability added to the app entitlements
- `WorkoutEntry` properties must all be CloudKit-compatible types (they already are)
- A `CKContainer` identifier registered in App Store Connect

---

## Edge cases

| Scenario | Behaviour |
|----------|-----------|
| First launch on new device | Entries sync down in background; streak appears correct within ~30 seconds |
| Two devices log simultaneously | Both entries preserved; streak re-calculated from merged set |
| iCloud disabled | App works fully offline; no error shown (silent degradation) |
| iCloud storage full | Sync silently pauses; local data unaffected |

---

## Acceptance criteria

- [ ] iCloud capability enabled in Xcode project
- [ ] `ModelContainer` configured with `cloudKitDatabase: .automatic`
- [ ] Entries logged on iPhone appear on iPad within 60 seconds
- [ ] App works fully offline when iCloud is unavailable
- [ ] No user-facing "sync" UI required — it happens transparently
- [ ] Streak is correct after restoring from new device
