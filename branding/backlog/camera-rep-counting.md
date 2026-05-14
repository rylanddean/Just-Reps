# Camera Rep Counting

> Just do the reps. The phone keeps count.

---

## Summary

Use the front or rear camera with Vision + CoreML to detect and count reps in real time. The user points their phone at themselves, starts a set, and the count increments automatically. When they finish, they confirm and the session logs.

---

## Why it fits the brand

This is the ultimate expression of "one-tap completion" — it becomes zero-tap. The user doesn't interact at all during the set. This also unlocks perfect form detection as a V2 feature.

---

## Supported exercises (V1)

| Exercise | Detection method |
|----------|-----------------|
| Pushups | Prone position, hip height oscillation via body landmarks |
| Squats | Standing, hip-to-knee angle threshold crossing |
| Situps | Supine position, shoulder elevation |

Custom exercises: not supported. Camera counting requires a trained model per exercise type.

---

## Technical approach

**Framework:** Apple Vision (`VNDetectHumanBodyPoseRequest`) — no third-party ML required.

**Rep detection algorithm:**
1. Extract `VNHumanBodyPoseObservation` at 30fps
2. Track a key joint angle (e.g., hip angle for squats, wrist height for pushups)
3. Smooth the signal with a rolling average (reduce false positives)
4. Count a rep when the angle crosses the "down" threshold then returns to "up"

**Confidence threshold:** Only count if body pose confidence > 0.7. If confidence drops, pause counting and show a warning.

**Privacy:** Camera feed is processed entirely on-device. No frames are stored or transmitted.

---

## UX flow

1. Tap the camera icon on an `ExerciseCard`
2. Camera opens in portrait, full-screen, dark overlay
3. Countdown: "3… 2… 1… Go"
4. Large rep count increments in real time
5. User says "done" (or taps screen) → summary: "22 pushups. Log it?"
6. Confirm → `WorkoutEntry` inserted, camera closes

---

## Failure states

| Condition | Response |
|-----------|----------|
| Body not detected | "Move back a bit." |
| Low confidence | Count pauses, "Adjust your position." |
| Too dark | "Need more light." |
| User too close | "Back up so your full body is visible." |

---

## Constraints

- **iOS 17+** required (latest Vision body pose APIs)
- **Requires camera permission** — requested only on first use
- **Battery impact:** High CPU usage; auto-stops after 10 minutes with a warning at 5
- **Accuracy:** ~90% on pushups and squats in good lighting; disclosed to user on first use

---

## Acceptance criteria

- [ ] Pushups, squats, situps correctly counted with ≥85% accuracy in test conditions
- [ ] Camera permission requested gracefully with brand-aligned copy
- [ ] All processing on-device, zero network calls
- [ ] Count confirmation step before logging (user can edit the number)
- [ ] Auto-stop after 10 minutes
- [ ] Works in both orientations (landscape for floor exercises)
- [ ] Graceful degradation when pose detection fails
