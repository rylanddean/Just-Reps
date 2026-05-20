import SwiftUI
import SwiftData

// Unified display model for both built-in achievements and custom milestones.
struct MilestoneItem: Identifiable {
    enum Source {
        case builtin(Achievement)
        case custom(CustomMilestone)
    }

    let source: Source
    let emoji: String
    let progress: Double
    let progressLabel: String

    var id: String {
        switch source {
        case .builtin(let a): return "builtin-\(a.id)"
        case .custom(let m): return m.id.uuidString
        }
    }

    var title: String {
        switch source {
        case .builtin(let a): return a.title
        case .custom(let m): return m.title
        }
    }

    var isCompleted: Bool { progress >= 1.0 }

    var isCustom: Bool {
        if case .custom = source { return true }
        return false
    }

    var customMilestone: CustomMilestone? {
        if case .custom(let m) = source { return m }
        return nil
    }
}

@Observable
final class StreakViewModel {

    private(set) var allEntries: [WorkoutEntry] = []

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
    }

    // MARK: - Derived

    var streakResult: StreakEngine.Result {
        StreakEngine.calculate(entries: allEntries)
    }

    var currentStreak: Int { streakResult.current }
    var longestStreak: Int { streakResult.longest }

    var monthlyConsistency: Double {
        StreakEngine.monthlyConsistency(entries: allEntries)
    }

    var heatmapData: [DateComponents: Int] {
        StreakEngine.heatmapData(entries: allEntries)
    }

    var restDays: Set<DateComponents> {
        StreakEngine.restDays(entries: allEntries)
    }

    var freezeDays: Set<DateComponents> {
        StreakEngine.freezeDays(entries: allEntries)
    }

    var muscleGroupCoverageThisWeek: Set<MuscleGroup> {
        let calendar = Calendar.current
        let today = Date.now
        let daysFromSunday = calendar.component(.weekday, from: today) - 1
        let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: calendar.startOfDay(for: today))!
        return Set(
            allEntries
                .filter { $0.kind == .workout && $0.timestamp >= weekStart }
                .flatMap { $0.exercise.muscleGroups }
        )
    }

    var weeklyAverageBuckets: [StreakAnalytics.Bucket] {
        StreakAnalytics.averageBuckets(entries: allEntries, period: .weekly)
    }

    var monthlyAverageBuckets: [StreakAnalytics.Bucket] {
        StreakAnalytics.averageBuckets(entries: allEntries, period: .monthly)
    }

    func summaries(for period: StreakAnalytics.Period) -> [StreakAnalytics.Summary] {
        StreakAnalytics.summaries(entries: allEntries, period: period)
    }

    func chartPoints(for period: StreakAnalytics.Period) -> [StreakAnalytics.ChartPoint] {
        StreakAnalytics.chartPoints(entries: allEntries, period: period)
    }

    func visibleExercises(for period: StreakAnalytics.Period) -> [ExerciseType] {
        StreakAnalytics.visibleExercises(in: buckets(for: period))
    }

    // MARK: - Goal streak

    var goalStreak: Int {
        let saved = Self.sharedDefaults.stringArray(forKey: Self.completedGoalDaysKey) ?? []
        let days = saved.compactMap { key -> DateComponents? in
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return DateComponents(year: parts[0], month: parts[1], day: parts[2])
        }
        return StreakEngine.calculateStreak(from: Set(days)).current
    }

    var activeExercises: [ExerciseType] {
        let raw = Self.sharedDefaults.stringArray(forKey: Self.exercisesKey) ?? []
        return raw.isEmpty ? ExerciseType.defaults : raw.map { ExerciseType(rawString: $0) }
    }

    private static let appGroupID = "group.com.rylanddean.justreps"
    private static let exercisesKey = "activeExercises"
    private static let completedGoalDaysKey = "completedGoalDays"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Milestones

    func milestoneItems(customMilestones: [CustomMilestone]) -> [MilestoneItem] {
        let builtIn = Achievement.all.map { a in
            MilestoneItem(
                source: .builtin(a),
                emoji: a.emoji,
                progress: achievementProgress(a),
                progressLabel: achievementProgressLabel(a)
            )
        }
        let custom = customMilestones.map { m in
            MilestoneItem(
                source: .custom(m),
                emoji: customMilestoneEmoji(m),
                progress: customMilestoneProgress(m),
                progressLabel: customMilestoneProgressLabel(m)
            )
        }
        return builtIn + custom
    }

    private func customMilestoneProgress(_ m: CustomMilestone) -> Double {
        switch m.metricType {
        case "repStreak":
            return min(Double(currentStreak) / Double(m.target), 1.0)
        case "goalStreak":
            return min(Double(goalStreak) / Double(m.target), 1.0)
        case "totalReps":
            guard let raw = m.exerciseRaw else { return 0 }
            let total = allEntries.filter { $0.exercise.rawString == raw }.reduce(0) { $0 + $1.reps }
            return min(Double(total) / Double(m.target), 1.0)
        default:
            return 0
        }
    }

    private func customMilestoneProgressLabel(_ m: CustomMilestone) -> String {
        switch m.metricType {
        case "repStreak":
            return "\(min(currentStreak, m.target)) / \(m.target) days"
        case "goalStreak":
            return "\(min(goalStreak, m.target)) / \(m.target) days"
        case "totalReps":
            guard let raw = m.exerciseRaw else { return "" }
            let total = allEntries.filter { $0.exercise.rawString == raw }.reduce(0) { $0 + $1.reps }
            return "\(min(total, m.target)) / \(m.target)"
        default:
            return ""
        }
    }

    private func customMilestoneEmoji(_ m: CustomMilestone) -> String {
        switch m.metricType {
        case "repStreak": return "🔥"
        case "goalStreak": return "⭐️"
        case "totalReps":
            if let raw = m.exerciseRaw { return ExerciseType(rawString: raw).emoji }
            return "⚡️"
        default: return "⚡️"
        }
    }

    // MARK: - Built-in achievement progress (used by milestoneItems)

    var earnedAchievements: [Achievement] {
        Achievement.all.filter { isEarned($0) }
    }

    func achievementProgress(_ achievement: Achievement) -> Double {
        switch achievement.condition {
        case .streakReached(let n):
            return min(Double(currentStreak) / Double(n), 1.0)
        case .totalRepsReached(let exerciseName, let count):
            let total = allEntries
                .filter { $0.exercise.rawString == exerciseName }
                .reduce(0) { $0 + $1.reps }
            return min(Double(total) / Double(count), 1.0)
        case .neverMissedWeekday(let weekday):
            let calendar = Calendar.current
            let completedDates = streakResult.completedDates
            var date = Date.now
            var successCount = 0
            for _ in 0..<4 {
                while calendar.component(.weekday, from: date) != weekday {
                    date = calendar.date(byAdding: .day, value: -1, to: date)!
                }
                let key = calendar.dateComponents([.year, .month, .day], from: date)
                if completedDates.contains(key) { successCount += 1 }
                date = calendar.date(byAdding: .day, value: -7, to: date)!
            }
            return Double(successCount) / 4.0
        }
    }

    func achievementProgressLabel(_ achievement: Achievement) -> String {
        switch achievement.condition {
        case .streakReached(let n):
            return "\(min(currentStreak, n)) / \(n) days"
        case .totalRepsReached(let exerciseName, let count):
            let total = allEntries
                .filter { $0.exercise.rawString == exerciseName }
                .reduce(0) { $0 + $1.reps }
            return "\(min(total, count)) / \(count)"
        case .neverMissedWeekday:
            let achieved = Int((achievementProgress(achievement) * 4).rounded())
            return "\(achieved) / 4 Mondays"
        }
    }

    // MARK: - Internal

    func buckets(for period: StreakAnalytics.Period) -> [StreakAnalytics.Bucket] {
        switch period {
        case .weekly:
            return weeklyAverageBuckets
        case .monthly:
            return monthlyAverageBuckets
        }
    }

    // MARK: - Private

    private func isEarned(_ achievement: Achievement) -> Bool {
        switch achievement.condition {
        case .streakReached(let n):
            return currentStreak >= n

        case .totalRepsReached(let exerciseName, let count):
            let total = allEntries
                .filter { $0.exercise.rawString == exerciseName }
                .reduce(0) { $0 + $1.reps }
            return total >= count

        case .neverMissedWeekday(let weekday):
            let calendar = Calendar.current
            let completedDates = streakResult.completedDates
            var date = Date.now
            var consecutiveMisses = 0
            for _ in 0..<4 {
                while calendar.component(.weekday, from: date) != weekday {
                    date = calendar.date(byAdding: .day, value: -1, to: date)!
                }
                let key = calendar.dateComponents([.year, .month, .day], from: date)
                if !completedDates.contains(key) { consecutiveMisses += 1 }
                date = calendar.date(byAdding: .day, value: -7, to: date)!
            }
            return consecutiveMisses == 0
        }
    }
}
