import SwiftUI
import SwiftData

@Observable
final class WatchViewModel {

    private(set) var activeExercises: [ExerciseType] = ExerciseType.defaults
    private(set) var dailyGoals: [String: Int] = ["pushups": 25, "squats": 50]
    private var allEntries: [WorkoutEntry] = []

    init() { loadPreferences() }

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
    }

    // MARK: - Today

    private var todaysEntries: [WorkoutEntry] {
        let today = StreakEngine.logicalDay(for: .now)
        return allEntries.filter { StreakEngine.logicalDay(for: $0.timestamp) == today }
    }

    func totalReps(for exercise: ExerciseType) -> Int {
        todaysEntries
            .filter { $0.exercise == exercise }
            .reduce(0) { $0 + $1.reps }
    }

    func goal(for exercise: ExerciseType) -> Int {
        dailyGoals[exercise.rawString] ?? (exercise == .squats ? 50 : 25)
    }

    func progress(for exercise: ExerciseType) -> Double {
        min(Double(totalReps(for: exercise)) / Double(goal(for: exercise)), 1.0)
    }

    func goalMet(for exercise: ExerciseType) -> Bool {
        totalReps(for: exercise) >= goal(for: exercise)
    }

    var allGoalsMet: Bool {
        activeExercises.allSatisfy { goalMet(for: $0) }
    }

    // MARK: - Streaks

    var loggedStreak: Int {
        StreakEngine.calculate(entries: allEntries).current
    }

    var goalsStreak: Int {
        StreakEngine.calculateStreak(from: goalCompletedDays()).current
    }

    // MARK: - Activity (last 7 logical days)

    var last7DaysActivity: [(date: Date, reps: Int)] {
        let calendar = Calendar.current
        let heatmap = StreakEngine.heatmapData(entries: allEntries, days: 7)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let key = StreakEngine.logicalDay(for: date)
            return (date: date, reps: heatmap[key] ?? 0)
        }
    }

    // MARK: - Logging

    func logReps(_ reps: Int, for exercise: ExerciseType, context: ModelContext) {
        let entry = WorkoutEntry(exercise: exercise, reps: reps)
        context.insert(entry)
    }

    // MARK: - Helpers

    private func goalCompletedDays() -> Set<DateComponents> {
        var dayMap: [DateComponents: [WorkoutEntry]] = [:]
        for entry in allEntries {
            let day = StreakEngine.logicalDay(for: entry.timestamp)
            dayMap[day, default: []].append(entry)
        }
        var completed = Set<DateComponents>()
        for (day, entries) in dayMap {
            let allMet = activeExercises.allSatisfy { exercise in
                let reps = entries
                    .filter { $0.exercise == exercise }
                    .reduce(0) { $0 + $1.reps }
                return reps >= goal(for: exercise)
            }
            if allMet { completed.insert(day) }
        }
        return completed
    }

    // MARK: - Preferences (App Group UserDefaults)

    private static let appGroupID = "group.com.rylanddean.justreps"
    private static let exercisesKey = "activeExercises"
    private static let goalsKey = "dailyGoals"

    private func loadPreferences() {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        if let raw = defaults.stringArray(forKey: Self.exercisesKey), !raw.isEmpty {
            activeExercises = raw.map { ExerciseType(rawString: $0) }
        }
        if let goals = defaults.dictionary(forKey: Self.goalsKey) as? [String: Int] {
            dailyGoals = goals
        }
    }
}
