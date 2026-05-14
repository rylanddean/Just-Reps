import SwiftUI
import SwiftData

struct WatchGoalRec {
    let exercise: ExerciseType
    let currentGoal: Int
    let suggestedGoal: Int
    let increase: Bool
}

@Observable
final class WatchViewModel {

    private(set) var activeExercises: [ExerciseType] = ExerciseType.defaults
    private(set) var dailyGoals: [String: Int] = ["pushups": 25, "squats": 50]
    private var allEntries: [WorkoutEntry] = []

    // MARK: - Training Load

    private(set) var trainingLoadTodayMins = 0
    private(set) var trainingLoadWeeklyMins = 0
    private(set) var trainingLoadTrend = "neutral"
    private(set) var hasTrainingLoadData = false

    init() { loadPreferences() }

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
        loadPreferences()
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

    func logReps(_ reps: Int, for exercise: ExerciseType, context: ModelContext) {
        let entry = WorkoutEntry(exercise: exercise, reps: reps)
        context.insert(entry)
    }

    // MARK: - Goal Recommendations

    var goalRecommendations: [WatchGoalRec] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let dayStarts: [Date] = (1...7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: todayStart)
        }

        var recs: [WatchGoalRec] = []

        for exercise in activeExercises {
            guard exercise != .stretching else { continue }
            let goalValue = goal(for: exercise)
            var daysWithActivity = 0
            var daysGoalMet = 0
            var rpeValues: [Double] = []

            for dayStart in dayStarts {
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                let dayEntries = allEntries.filter {
                    $0.exercise == exercise &&
                    $0.timestamp >= dayStart &&
                    $0.timestamp < dayEnd
                }
                guard !dayEntries.isEmpty else { continue }
                daysWithActivity += 1
                if dayEntries.reduce(0, { $0 + $1.reps }) >= goalValue { daysGoalMet += 1 }
                rpeValues.append(contentsOf: dayEntries.compactMap { $0.effortRPE })
            }

            guard daysWithActivity >= 4 else { continue }

            let avgRPE = rpeValues.isEmpty ? nil : rpeValues.reduce(0, +) / Double(rpeValues.count)

            let shouldIncrease = daysGoalMet >= 6
                && (avgRPE == nil || avgRPE! <= 5.0)
                && trainingLoadTrend != "up"

            let shouldDecrease = daysGoalMet <= 3
                || (avgRPE != nil && avgRPE! >= 7.5 && daysGoalMet < 5)
                || (trainingLoadTrend == "up" && avgRPE != nil && avgRPE! >= 7.5)

            if shouldIncrease {
                let suggested = roundToNearest5(Int(Double(goalValue) * 1.15))
                if suggested != goalValue {
                    recs.append(WatchGoalRec(exercise: exercise, currentGoal: goalValue, suggestedGoal: suggested, increase: true))
                }
            } else if shouldDecrease {
                let suggested = max(5, roundToNearest5(Int(Double(goalValue) * 0.85)))
                if suggested != goalValue {
                    recs.append(WatchGoalRec(exercise: exercise, currentGoal: goalValue, suggestedGoal: suggested, increase: false))
                }
            }
        }
        return recs
    }

    func applyGoalRecommendation(_ rec: WatchGoalRec) {
        dailyGoals[rec.exercise.rawString] = rec.suggestedGoal
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        defaults.set(dailyGoals, forKey: Self.goalsKey)
    }

    // MARK: - Milestones

    static let milestoneThresholds = [3, 7, 14, 30, 60, 100]

    func nextMilestone(for streak: Int) -> Int? {
        Self.milestoneThresholds.first { $0 > streak }
    }

    // MARK: - Helpers

    private func roundToNearest5(_ value: Int) -> Int {
        Int((Double(value) / 5.0).rounded()) * 5
    }

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
        trainingLoadTodayMins = defaults.integer(forKey: "trainingLoadTodayMins")
        trainingLoadWeeklyMins = defaults.integer(forKey: "trainingLoadWeeklyMins")
        trainingLoadTrend = defaults.string(forKey: "trainingLoadTrend") ?? "neutral"
        hasTrainingLoadData = defaults.object(forKey: "trainingLoadTodayMins") != nil
    }
}
