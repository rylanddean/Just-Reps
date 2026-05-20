import SwiftUI
import WidgetKit

@Observable
final class WatchViewModel {

    private(set) var activeExercises: [ExerciseType] = ExerciseType.defaults
    private(set) var dailyGoals: [String: Int] = ["pushups": 25, "squats": 50]

    // Entries received from the phone (source of truth)
    private var phoneEntries: [WorkoutEntry] = []
    // Entries logged on watch but not yet confirmed by phone
    private var pendingEntries: [WorkoutEntry] = []

    private var allEntries: [WorkoutEntry] {
        let phoneIds = Set(phoneEntries.map { $0.id })
        let unconfirmed = pendingEntries.filter { !phoneIds.contains($0.id) }
        return phoneEntries + unconfirmed
    }

    // MARK: - Apply context from phone (via WatchSessionManager)

    func applyPhoneContext(entries: [WorkoutEntry], exercises: [ExerciseType], goals: [String: Int]) {
        let phoneIds = Set(entries.map { $0.id })
        pendingEntries.removeAll { phoneIds.contains($0.id) }
        phoneEntries = entries
        activeExercises = exercises
        dailyGoals = goals
        persistStreakForComplication()
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
        if let g = dailyGoals[exercise.rawString] { return g }
        switch exercise {
        case .squats:     return 50
        case .stretching: return 1
        default:          return 25
        }
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

    // Optimistically adds to pending and sends to phone via WCSession.
    func logReps(_ reps: Int, for exercise: ExerciseType) {
        let entry = WorkoutEntry(exercise: exercise, reps: reps)
        pendingEntries.append(entry)
        WatchSessionManager.shared.send(entry)
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

    // MARK: - Complication

    private static let appGroupID = "group.com.rylanddean.justreps"

    private func persistStreakForComplication() {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        defaults.set(loggedStreak, forKey: "currentRepStreak")
        let activity = last7DaysActivity.map { $0.reps > 0 }
        if let data = try? JSONEncoder().encode(activity) {
            defaults.set(data, forKey: "last7DaysActivity")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
