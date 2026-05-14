import SwiftUI
import SwiftData

@Observable
final class HomeViewModel {

    // MARK: - Persistent state (survives app restarts)

    var activeExercises: [ExerciseType] {
        didSet { saveExercises() }
    }

    var dailyGoals: [String: Int] {
        didSet { saveGoals() }
    }

    var showCompletionBanner = false

    // MARK: - Live entries (fed by @Query in the view)

    private(set) var todaysEntries: [WorkoutEntry] = []
    private var allEntries: [WorkoutEntry] = []
    private var bannerAlreadyShown = false

    // MARK: - Init

    init() {
        activeExercises = Self.loadExercises()
        dailyGoals = Self.loadGoals()
    }

    // MARK: - Refresh from @Query

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
        let today = StreakEngine.logicalDay(for: .now)
        todaysEntries = entries.filter { StreakEngine.logicalDay(for: $0.timestamp) == today }

        if allGoalsMet && !bannerAlreadyShown {
            bannerAlreadyShown = true
            withAnimation(.easeOut(duration: 0.4)) { showCompletionBanner = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                withAnimation { self.showCompletionBanner = false }
            }
        }

        if !allGoalsMet { bannerAlreadyShown = false }
    }

    // MARK: - Day state

    enum DayState {
        case fresh    // no reps logged yet today
        case alive    // some reps, not all goals met
        case complete // all goals met
    }

    var dayState: DayState {
        if allGoalsMet { return .complete }
        if !todaysEntries.isEmpty { return .alive }
        return .fresh
    }

    // MARK: - Streaks

    /// Consecutive days where ANY reps were logged (keeps chain alive).
    var loggedStreak: Int { StreakEngine.calculate(entries: allEntries).current }

    /// Consecutive days where ALL active exercise goals were fully met.
    var goalsStreak: Int {
        StreakEngine.calculateStreak(from: goalCompletedDays()).current
    }

    /// Logged streak is at risk: has a streak, it's after 8 PM, nothing logged today.
    var streakAtRisk: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return loggedStreak > 0 && hour >= 20 && todaysEntries.isEmpty
    }

    /// Goals streak is at risk: has a goals streak, it's after 8 PM, goals not yet met today.
    var goalsStreakAtRisk: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return goalsStreak > 0 && hour >= 20 && !allGoalsMet
    }

    var completedToday: Bool { StreakEngine.completedToday(entries: todaysEntries) }

    // MARK: - Goals streak helpers

    private func goalCompletedDays() -> Set<DateComponents> {
        // Group all-time entries by logical day
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

    // MARK: - Derived

    func totalReps(for exercise: ExerciseType) -> Int {
        todaysEntries
            .filter { $0.exercise == exercise }
            .reduce(0) { $0 + $1.reps }
    }

    func goal(for exercise: ExerciseType) -> Int {
        dailyGoals[exercise.rawString] ?? defaultGoal(for: exercise)
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

    // MARK: - Actions

    func logReps(_ reps: Int, for exercise: ExerciseType, context: ModelContext) {
        let entry = WorkoutEntry(exercise: exercise, reps: reps)
        context.insert(entry)

        guard UserDefaults.standard.bool(forKey: "healthKitEnabled") else { return }
        let stored = UserDefaults.standard.integer(forKey: "repsPerMinute")
        let repsPerMinute = stored > 0 ? stored : 20
        Task {
            await HealthKitManager.shared.logWorkout(
                exercise: exercise,
                reps: reps,
                repsPerMinute: repsPerMinute
            )
        }
    }

    func setGoal(_ goal: Int, for exercise: ExerciseType) {
        dailyGoals[exercise.rawString] = goal
    }

    // MARK: - Persistence

    private static let appGroupID = "group.com.rylanddean.justreps"
    private static let exercisesKey = "activeExercises"
    private static let goalsKey = "dailyGoals"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private func saveExercises() {
        let raw = activeExercises.map { $0.rawString }
        Self.sharedDefaults.set(raw, forKey: Self.exercisesKey)
    }

    private func saveGoals() {
        Self.sharedDefaults.set(dailyGoals, forKey: Self.goalsKey)
    }

    private static func loadExercises() -> [ExerciseType] {
        guard let raw = sharedDefaults.stringArray(forKey: exercisesKey), !raw.isEmpty else {
            return ExerciseType.defaults
        }
        return raw.map { ExerciseType(rawString: $0) }
    }

    private static func loadGoals() -> [String: Int] {
        let saved = sharedDefaults.dictionary(forKey: goalsKey) as? [String: Int]
        return saved ?? ["pushups": 25, "squats": 50]
    }

    private func defaultGoal(for exercise: ExerciseType) -> Int {
        switch exercise {
        case .squats: return 50
        default:      return 25
        }
    }
}
