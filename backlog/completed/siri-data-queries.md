# Siri Data Queries

> Ask Siri. Get an answer. Don't open the app.

---

## Summary

A set of query-type App Intents that let users ask Siri natural-language questions about their Just Reps data. Apple Intelligence enhances Siri's understanding so these work conversationally, not just as rigid phrases. "What's my streak?" / "Did I log today?" / "How many pushups this week?" — Siri speaks the answer and the app never needs to open.

**Distinct from Siri & App Intents (logging):** That item covers *writing* to Just Reps (logging reps). This item covers *reading* from Just Reps (querying data). Together they make Just Reps fully voice-accessible.

---

## Why it fits the brand

Just Reps is already the shortest interaction in fitness. Siri data queries make it even shorter: no unlock, no navigation, no screen. A user lying in bed can ask "Did I log today?" and know immediately. That's the app fulfilling its promise — get in, get out — without even showing up. Apple Intelligence's improved natural language understanding means users don't have to memorise a specific phrase; they ask naturally and it works.

---

## User story

> As someone who logs at random times during the day, I want to ask Siri whether I've logged yet — so I don't need to open the app just to check.

---

## Apple Intelligence technical approach

**Framework:** `AppIntents` (iOS 16+), with enhanced natural language understanding from Apple Intelligence (iOS 18.2+)

Apple Intelligence extends Siri's ability to map ambiguous natural language to specific intents. The intent definitions are standard `AppIntent`; Apple Intelligence handles fuzzy phrase matching.

---

## Intent definitions

### 1. `GetCurrentStreakIntent`

```swift
struct GetCurrentStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current streak"
    static var description = IntentDescription("Check your current rep streak in Just Reps.")

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let streak = StreakEngine.calculate(entries: fetchTodayEntries()).current
        return .result(
            value: streak,
            dialog: "\(streak) day streak."
        )
    }
}
```

**Example phrases Siri handles:**
- "What's my Just Reps streak?"
- "How long is my streak?"
- "What's my streak in Just Reps?"

---

### 2. `GetTodayStatusIntent`

```swift
struct GetTodayStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check today's logging status"
    static var description = IntentDescription("Ask whether you've logged any reps today.")

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let loggedToday = hasLoggedToday()
        let response = loggedToday ? "You've logged today." : "You haven't logged yet."
        return .result(value: loggedToday, dialog: IntentDialog(response))
    }
}
```

**Example phrases:**
- "Did I log today in Just Reps?"
- "Have I done my reps today?"
- "Did I work out in Just Reps today?"

---

### 3. `GetWeeklyTotalsIntent`

```swift
struct GetWeeklyTotalsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get weekly rep totals"
    static var description = IntentDescription("Hear how many reps you've logged this week per exercise.")

    @Parameter(title: "Exercise", optionality: .optional) var exercise: ExerciseEntity?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // If exercise provided: "You've done 120 push-ups this week."
        // If no exercise: "This week: 120 push-ups, 80 squats."
        let summary = buildWeeklySummary(for: exercise)
        return .result(value: summary, dialog: IntentDialog(summary))
    }
}
```

**Example phrases:**
- "How many pushups have I done this week in Just Reps?"
- "What are my Just Reps totals this week?"
- "How many reps this week?"

---

### 4. `GetLongestStreakIntent`

```swift
struct GetLongestStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Get longest streak"
    static var description = IntentDescription("Check your all-time longest streak in Just Reps.")

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let longest = StreakEngine.calculate(entries: allEntries()).longest
        return .result(value: longest, dialog: "\(longest) days — your personal best.")
    }
}
```

**Example phrases:**
- "What's my longest streak in Just Reps?"
- "What's my personal best in Just Reps?"

---

## App Intents Shortcuts app integration

All four intents appear in the Shortcuts app automatically, enabling:
- Widgets that speak the streak
- Automations: "Every evening at 9PM, ask if I've logged today"
- Lock screen shortcuts

These are user-built — Just Reps does not create automations on the user's behalf.

---

## Shared data access

Same constraint as `LogRepsIntent`: intents run in a separate process. If SwiftData is app-local, the intents must access it via a shared App Group container or a data bridge. Address in the same implementation pass as the logging App Intent if the data access issue hasn't been solved yet.

---

## Acceptance criteria

- [ ] `GetCurrentStreakIntent` responds with correct current streak count
- [ ] `GetTodayStatusIntent` accurately reflects whether any entry exists for today's logical day
- [ ] `GetWeeklyTotalsIntent` returns correct per-exercise totals for the current calendar week
- [ ] `GetLongestStreakIntent` returns correct all-time longest streak
- [ ] All intents respond without opening the app (background execution)
- [ ] All four intents appear in the Shortcuts app
- [ ] Natural language variants work via Siri ("Have I done my reps?" not just the exact phrase)
- [ ] Intents use logical day boundary (3AM), not calendar midnight

---

## What this is NOT

- Not a conversational back-and-forth — each intent is one question, one answer
- Not a full history query system ("how did I do last Tuesday?") — out of scope for V1
- Not a replacement for the app — it's a quick check, not a logging session
- Not dependent on Apple Intelligence to function — works on any device via Shortcuts; AI improves phrase recognition but isn't required
