import AppIntents
import Foundation
import SwiftData

// MARK: - Shared data access

private enum IntentDataStore {
    static let appGroupID = "group.com.rylanddean.justreps"
    static let exercisesKey = "activeExercises"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var activeExercises: [ExerciseType] {
        guard let raw = sharedDefaults.stringArray(forKey: exercisesKey), !raw.isEmpty else {
            return ExerciseType.defaults
        }
        return raw.map { ExerciseType(rawString: $0) }
    }

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([WorkoutEntry.self, CustomMilestone.self])
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID),
           let container = try? ModelContainer(for: schema, configurations: [
               ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("JustReps.sqlite"))
           ]) {
            return container
        }
        return try ModelContainer(for: schema)
    }

    static func fetchAllEntries(from container: ModelContainer) throws -> [WorkoutEntry] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<WorkoutEntry>())
    }
}

// MARK: - Exercise entity (for GetWeeklyTotalsIntent parameter)

struct ExerciseEntity: AppEntity {
    var id: String
    var displayName: String

    static var defaultQuery = ExerciseQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Exercise")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayName))
    }
}

struct ExerciseQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ExerciseEntity] {
        IntentDataStore.activeExercises
            .filter { identifiers.contains($0.rawString) }
            .map { ExerciseEntity(id: $0.rawString, displayName: $0.displayName) }
    }

    func suggestedEntities() async throws -> [ExerciseEntity] {
        IntentDataStore.activeExercises
            .map { ExerciseEntity(id: $0.rawString, displayName: $0.displayName) }
    }
}

// MARK: - Siri phrase registration

struct JustRepsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetCurrentStreakIntent(),
            phrases: [
                "What's my \(.applicationName) streak?",
                "Check my streak in \(.applicationName)",
                "How long is my streak in \(.applicationName)?",
            ],
            shortTitle: "Current streak",
            systemImageName: "flame"
        )
        AppShortcut(
            intent: GetTodayStatusIntent(),
            phrases: [
                "Did I log today in \(.applicationName)?",
                "Have I done my reps in \(.applicationName)?",
                "Did I work out in \(.applicationName) today?",
            ],
            shortTitle: "Today's status",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: GetWeeklyTotalsIntent(),
            phrases: [
                "How many reps this week in \(.applicationName)?",
                "What are my \(.applicationName) totals this week?",
            ],
            shortTitle: "Weekly totals",
            systemImageName: "chart.bar"
        )
        AppShortcut(
            intent: GetLongestStreakIntent(),
            phrases: [
                "What's my longest streak in \(.applicationName)?",
                "What's my personal best in \(.applicationName)?",
            ],
            shortTitle: "Longest streak",
            systemImageName: "trophy"
        )
    }
}

// MARK: - GetCurrentStreakIntent

struct GetCurrentStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current streak"
    static var description = IntentDescription("Check your current rep streak in Just Reps.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let container = try IntentDataStore.makeContainer()
        let entries = try IntentDataStore.fetchAllEntries(from: container)
        let streak = StreakEngine.calculate(entries: entries).current
        let message: String = streak == 0
            ? "No streak yet. Log some reps today."
            : "Your current rep streak is \(streak) \(streak == 1 ? "day" : "days")."
        return .result(value: streak, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - GetTodayStatusIntent

struct GetTodayStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check today's logging status"
    static var description = IntentDescription("Ask whether you've logged any reps today.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let container = try IntentDataStore.makeContainer()
        let entries = try IntentDataStore.fetchAllEntries(from: container)
        let loggedToday = StreakEngine.completedToday(entries: entries)
        let message: String = loggedToday ? "You've logged today." : "You haven't logged yet."
        return .result(value: loggedToday, dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - GetWeeklyTotalsIntent

struct GetWeeklyTotalsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get weekly rep totals"
    static var description = IntentDescription("Hear how many reps you've logged this week per exercise.")
    static var openAppWhenRun = false

    @Parameter(title: "Exercise") var exercise: ExerciseEntity?

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let container = try IntentDataStore.makeContainer()
        let entries = try IntentDataStore.fetchAllEntries(from: container)

        let calendar = Calendar.current
        let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        )!
        let weekEntries = entries.filter { $0.timestamp >= weekStart && $0.kind == .workout }

        let summary: String
        if let exercise {
            let exerciseType = ExerciseType(rawString: exercise.id)
            let total = weekEntries
                .filter { $0.exercise == exerciseType }
                .reduce(0) { $0 + $1.reps }
            summary = total == 0
                ? "No \(exercise.displayName.lowercased()) logged this week."
                : "\(total) \(exerciseType.unit) of \(exercise.displayName.lowercased()) this week."
        } else {
            var grouped: [String: (total: Int, unit: String)] = [:]
            for entry in weekEntries {
                let key = entry.exercise.displayName
                grouped[key, default: (0, entry.exercise.unit)].total += entry.reps
            }
            if grouped.isEmpty {
                summary = "Nothing logged this week."
            } else {
                let parts = grouped.sorted { $0.key < $1.key }
                    .map { "\($0.value.total) \($0.value.unit) of \($0.key.lowercased())" }
                summary = "This week: \(parts.joined(separator: ", "))."
            }
        }

        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

// MARK: - GetLongestStreakIntent

struct GetLongestStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Get longest streak"
    static var description = IntentDescription("Check your all-time longest streak in Just Reps.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let container = try IntentDataStore.makeContainer()
        let entries = try IntentDataStore.fetchAllEntries(from: container)
        let longest = StreakEngine.calculate(entries: entries).longest
        let message: String = longest == 0
            ? "No streak on record yet."
            : "Your personal best is \(longest) \(longest == 1 ? "day" : "days")."
        return .result(value: longest, dialog: IntentDialog(stringLiteral: message))
    }
}
