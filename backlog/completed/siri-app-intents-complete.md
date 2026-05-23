# Siri & App Intents

> Log reps without opening the app.

---

## Summary

Expose a lightweight App Intents action — "Log reps" — so users can log to any exercise via Siri, the Shortcuts app, or a custom home screen shortcut. "Hey Siri, log 10 pushups in Just Reps." The app never needs to open. The count updates in the background. The streak is safe.

---

## Why it fits the brand

The brand promise is one tap to log. App Intents makes it *zero* taps — the lowest possible barrier to logging. It also keeps the app off-screen: you log, you move on. That's the "now go live your life" ethos applied to the logging act itself. No other exercise app treats Siri as a first-class input.

---

## User story

> As someone in the middle of a workout with sweaty hands, I want to say "log 10 pushups in Just Reps" — so I don't need to unlock my phone and navigate the app.

---

## Design

### Intent definition

```swift
struct LogRepsIntent: AppIntent {
    static var title: LocalizedStringResource = "Log reps"
    static var description = IntentDescription("Log reps to an exercise in Just Reps.")

    @Parameter(title: "Exercise") var exercise: ExerciseEntity
    @Parameter(title: "Reps") var reps: Int

    func perform() async throws -> some IntentResult {
        // Insert WorkoutEntry into shared ModelContainer
        // Return .result(value: "\(reps) \(exercise.name) logged.")
    }
}
```

### ExerciseEntity
Conforms to `AppEntity`. Returns the user's active exercises as options. Name matches the display name ("Push-ups", "Squats", etc.).

### Siri phrase examples
- "Log 10 push-ups in Just Reps"
- "Add 25 squats to Just Reps"
- "Log a plank in Just Reps"

### Confirmation
No confirmation dialog. The action is immediate. Siri speaks: `"10 push-ups logged."` That's it.

### Shared data access
Intents run in a separate process — the `ModelContainer` must be initialized in the intent using the same `AppGroup` or direct URL as the main app. If SwiftData is currently local-only, this requires extracting the container URL into a shared location or using an App Group. Plan this as part of the implementation.

### Shortcuts app
The intent appears automatically in the Shortcuts app. Users can build automations: "Every morning at 6AM, ask me how many push-ups I did." (That's their choice — Just Reps doesn't set up automations for them.)

---

## Acceptance criteria

- [ ] `LogRepsIntent` conforms to `AppIntent` and is declared in the app target
- [ ] Intent is discoverable by Siri without explicit phrase training
- [ ] `ExerciseEntity` returns the user's current active exercises as options
- [ ] Logging via Siri inserts a `WorkoutEntry` and updates today's count
- [ ] Home screen reflects the Siri-logged reps on next open without requiring a restart
- [ ] Works correctly across the 3AM grace window (logical day, not calendar day)
- [ ] No confirmation dialog — immediate, speaks result back
- [ ] Intent appears in Shortcuts app for custom automation

---

## What this is NOT

- Not a conversational interface — just a single action: log N reps of exercise X
- Not a way to view streak or history via Siri
- Not a widget replacement — it's a voice/shortcut input path
- Not an Apple Watch app replacement — Watch has its own logging path
