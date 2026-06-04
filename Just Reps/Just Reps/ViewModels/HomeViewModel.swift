import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class HomeViewModel {

    // MARK: - Persistent state (survives app restarts)

    var activeExercises: [ExerciseType] {
        didSet {
            saveExercises()
            syncToWatch()
        }
    }

    var dailyGoals: [String: Int] {
        didSet {
            saveGoals()
            syncToWatch()
        }
    }

    var minimumViableReps: [String: Int] = [:] {
        didSet { saveMVR() }
    }

    var showCompletionBanner = false
    var showEffortPicker = false
    /// Mirrors HealthKitManager.todaySteps so @Observable SwiftUI tracking fires on the viewModel.
    private(set) var walkingStepsToday: Int = 0
    private(set) var pendingEulogy: Int? = nil
    private(set) var freezeTokens: Int = 0

    // MARK: - Live entries (fed by @Query in the view)

    private(set) var todaysEntries: [WorkoutEntry] = []
    private var allEntries: [WorkoutEntry] = []
    private var bannerAlreadyShown = false
    private var pendingLogEntry: (exercise: ExerciseType, amount: Int)?
    private var completedGoalDays: Set<String> = []
    private var needsGoalDayMigration = false

    // MARK: - Init

    init() {
        activeExercises = Self.loadExercises()
        dailyGoals = Self.loadGoals()
        minimumViableReps = Self.loadMVR()
        // If MVR was configured before the effective-date feature existed, set tomorrow as the
        // effective date so all existing history stays qualified under the old "any reps" rule.
        let existingMVR = Self.loadMVR()
        let existingEffectiveDate = Self.sharedDefaults.double(forKey: Self.mvrEffectiveDateKey)
        if existingMVR.values.contains(where: { $0 > 0 }) && existingEffectiveDate == 0 {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
            Self.sharedDefaults.set(
                Calendar.current.startOfDay(for: tomorrow).timeIntervalSinceReferenceDate,
                forKey: Self.mvrEffectiveDateKey
            )
        }
        let saved = Self.sharedDefaults.stringArray(forKey: Self.completedGoalDaysKey)
        if let saved {
            completedGoalDays = Set(saved)
            needsGoalDayMigration = false
        } else {
            completedGoalDays = []
            needsGoalDayMigration = true
        }
        freezeTokens = Self.sharedDefaults.integer(forKey: Self.freezeTokensKey)
    }

    // MARK: - Refresh from @Query

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
        let today = StreakEngine.logicalDay(for: .now)
        todaysEntries = entries.filter { StreakEngine.logicalDay(for: $0.timestamp) == today }

        if needsGoalDayMigration && !entries.isEmpty {
            needsGoalDayMigration = false
            completedGoalDays = Set(computeHistoricalGoalDays().map { dayKey($0) })
            saveCompletedGoalDays()
        }

        let todayKey = dayKey(today)
        if allGoalsMet && !completedGoalDays.contains(todayKey) {
            completedGoalDays.insert(todayKey)
            saveCompletedGoalDays()
        }

        awardFreezeTokenIfEarned()
        Self.sharedDefaults.set(loggedStreak, forKey: Self.currentRepStreakKey)
        Self.sharedDefaults.set(goalsStreak, forKey: Self.currentGoalsStreakKey)
        GameCenterManager.shared.submitStreak(loggedStreak)
        if let heatmapData = try? JSONEncoder().encode(Self.buildWidgetHeatmap(entries: allEntries)) {
            Self.sharedDefaults.set(heatmapData, forKey: Self.widgetHeatmapKey)
        }
        WidgetCenter.shared.reloadAllTimelines()

        if allGoalsMet && !bannerAlreadyShown {
            bannerAlreadyShown = true
            withAnimation(.easeOut(duration: 0.4)) { showCompletionBanner = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                withAnimation { self.showCompletionBanner = false }
            }
        }

        if !allGoalsMet { bannerAlreadyShown = false }

        syncToWatch()
        checkEulogy()
        updateNotifications()
    }

    private func updateNotifications() {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            NotificationManager.shared.cancelAtRiskNotification()
            NotificationManager.shared.cancelEndOfDayReminder()
            return
        }

        let hasLoggedToday = todaysEntries.contains { $0.kind == .workout }
        if loggedStreak > 0 && !hasLoggedToday {
            NotificationManager.shared.scheduleAtRiskNotification(streak: loggedStreak)
        } else {
            NotificationManager.shared.cancelAtRiskNotification()
        }

        let endOfDayEnabled = (UserDefaults.standard.object(forKey: "endOfDayReminderEnabled") as? Bool) ?? true
        if endOfDayEnabled && !allGoalsMet {
            let hour   = (UserDefaults.standard.object(forKey: "endOfDayHour")   as? Int) ?? 18
            let minute = (UserDefaults.standard.object(forKey: "endOfDayMinute") as? Int) ?? 0
            NotificationManager.shared.scheduleEndOfDayReminder(hour: hour, minute: minute, body: endOfDayNotificationBody)
        } else {
            NotificationManager.shared.cancelEndOfDayReminder()
        }
    }

    var endOfDayNotificationBody: String {
        let parts = unmetExercises.map { "\($0.remaining) \($0.exercise.displayName.lowercased())" }
        switch parts.count {
        case 0:  return "Still time."
        case 1:  return "\(parts[0]) left."
        default: return "\(parts.joined(separator: " · ")) left."
        }
    }

    private func syncToWatch() {
        PhoneSessionManager.shared.pushContext(
            entries: allEntries,
            exercises: activeExercises,
            goals: dailyGoals,
            mvr: minimumViableReps,
            mvrEffectiveDate: mvrEffectiveDate,
            walkingStepsToday: walkingStepsToday
        )
    }

    // MARK: - Day state

    enum DayState {
        case fresh    // no reps logged yet today
        case alive    // some reps, not all goals met
        case complete // all goals met
    }

    var isRestDay: Bool {
        todaysEntries.contains { $0.kind == .rest }
    }

    var canMarkRestDay: Bool {
        guard !isRestDay else { return false }
        guard todaysEntries.filter({ $0.kind == .workout }).isEmpty else { return false }
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: .now)!
        return allEntries.filter { $0.kind == .rest && $0.timestamp >= cutoff }.isEmpty
    }

    var dayState: DayState {
        if allGoalsMet { return .complete }
        if !todaysEntries.filter({ $0.kind == .workout }).isEmpty { return .alive }
        return .fresh
    }

    // MARK: - Streaks

    /// Consecutive days where ANY reps were logged (keeps chain alive).
    /// When MVR is configured for at least one exercise, days must also meet those thresholds.
    var loggedStreak: Int {
        let mvrDict = Dictionary(uniqueKeysWithValues:
            minimumViableReps.compactMap { key, val -> (ExerciseType, Int)? in
                guard val > 0 else { return nil }
                return (ExerciseType(rawString: key), val)
            }
        )
        guard !mvrDict.isEmpty else {
            return StreakEngine.calculate(entries: allEntries).current
        }
        let goalsDict = Dictionary(uniqueKeysWithValues: activeExercises.map { ($0, goal(for: $0)) })
        return StreakEngine.calculate(
            entries: allEntries,
            activeExercises: activeExercises,
            goals: goalsDict,
            minimumViableReps: mvrDict,
            effectiveFrom: mvrEffectiveDate
        ).current
    }

    /// Consecutive days where ALL active exercise goals were fully met.
    var goalsStreak: Int {
        let days = completedGoalDays.compactMap { dayComponents(from: $0) }
        return StreakEngine.calculateStreak(from: Set(days)).current
    }

    /// Logged streak is at risk: has a streak, it's after 8 PM, nothing logged today.
    var streakAtRisk: Bool {
        guard !isRestDay else { return false }
        let hour = Calendar.current.component(.hour, from: .now)
        return loggedStreak > 0 && hour >= 20 && todaysEntries.isEmpty
    }

    /// Goals streak is at risk: has a goals streak, it's after 8 PM, goals not yet met today.
    var goalsStreakAtRisk: Bool {
        guard !isRestDay else { return false }
        let hour = Calendar.current.component(.hour, from: .now)
        return goalsStreak > 0 && hour >= 20 && !allGoalsMet
    }

    /// Whether yesterday was missed and a freeze token is available.
    var shouldShowFreezePrompt: Bool {
        guard freezeTokens > 0 else { return false }
        let yesterday = StreakEngine.previousLogicalDay(before: StreakEngine.logicalDay(for: .now))
        return !allEntries.contains { StreakEngine.logicalDay(for: $0.timestamp) == yesterday }
    }

    var completedToday: Bool { StreakEngine.completedToday(entries: todaysEntries) }

    // MARK: - Goals streak helpers

    private func computeHistoricalGoalDays() -> Set<DateComponents> {
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

    private func dayKey(_ dc: DateComponents) -> String {
        guard let y = dc.year, let m = dc.month, let d = dc.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    private func dayComponents(from key: String) -> DateComponents? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return DateComponents(year: parts[0], month: parts[1], day: parts[2])
    }

    private func saveCompletedGoalDays() {
        Self.sharedDefaults.set(Array(completedGoalDays), forKey: Self.completedGoalDaysKey)
    }

    private static func buildWidgetHeatmap(entries: [WorkoutEntry]) -> [String: Bool] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -91, to: .now)!
        var map: [String: Bool] = [:]
        for entry in entries where entry.timestamp >= cutoff && entry.kind == .workout {
            let dc = StreakEngine.logicalDay(for: entry.timestamp)
            guard let y = dc.year, let m = dc.month, let d = dc.day else { continue }
            map[String(format: "%04d-%02d-%02d", y, m, d)] = true
        }
        return map
    }

    // MARK: - Derived

    func totalReps(for exercise: ExerciseType) -> Int {
        // Walking steps come from HealthKit, stored locally so SwiftUI observes the change.
        if case .walking = exercise { return walkingStepsToday }
        return todaysEntries
            .filter { $0.kind == .workout && $0.exercise == exercise }
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
        guard Self.sharedDefaults.bool(forKey: "healthKitEnabled") else {
            commitLog(reps, for: exercise, effort: nil, context: context)
            return
        }
        pendingLogEntry = (exercise, reps)
        showEffortPicker = true
    }

    func confirmEffort(_ effort: WorkoutEffort?, context: ModelContext) {
        guard let pending = pendingLogEntry else { return }
        pendingLogEntry = nil
        showEffortPicker = false
        commitLog(pending.amount, for: pending.exercise, effort: effort, context: context)
    }

    private func commitLog(_ reps: Int, for exercise: ExerciseType, effort: WorkoutEffort?, context: ModelContext) {
        context.insert(WorkoutEntry(exercise: exercise, reps: reps, effortRPE: effort?.rpeValue))
        NotificationManager.shared.cancelAtRiskNotification()

        guard Self.sharedDefaults.bool(forKey: "healthKitEnabled") else { return }
        Task {
            await HealthKitManager.shared.logWorkout(
                exercise: exercise,
                reps: reps,
                effort: effort
            )
        }
    }

    /// Fetches today's step count from HealthKit and upserts a single WorkoutEntry for
    /// Walking so the streak engine counts the day. Idempotent — safe to call on every appear.
    func syncWalkingEntry(context: ModelContext) async {
        guard activeExercises.contains(where: { if case .walking = $0 { return true }; return false }) else { return }
        await HealthKitManager.shared.fetchTodaySteps()
        let steps = HealthKitManager.shared.todaySteps
        walkingStepsToday = steps
        Self.sharedDefaults.set(steps, forKey: Self.walkingStepsTodayKey)
        syncToWatch()
        guard steps > 0 else { return }
        // Upsert: update existing entry so streak history stays clean (no duplicate rows).
        if let existing = todaysEntries.first(where: { $0.exercise == .walking && $0.kind == .workout }) {
            existing.reps = steps
        } else {
            context.insert(WorkoutEntry(exercise: .walking, reps: steps))
        }
    }

    func setGoal(_ goal: Int, for exercise: ExerciseType) {
        dailyGoals[exercise.rawString] = goal
    }

    func mvr(for exercise: ExerciseType) -> Int {
        minimumViableReps[exercise.rawString] ?? 0
    }

    func setMVR(_ value: Int, for exercise: ExerciseType) {
        minimumViableReps[exercise.rawString] = value > 0 ? value : 0
        let anyActive = minimumViableReps.values.contains { $0 > 0 }
        if anyActive && mvrEffectiveDate == nil {
            // First time enabling MVR: take effect from tomorrow so today and all
            // prior history remain qualified under the original "any reps" rule.
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
            mvrEffectiveDate = Calendar.current.startOfDay(for: tomorrow)
        } else if !anyActive {
            mvrEffectiveDate = nil
        }
    }

    /// Exercises that haven't hit their daily goal yet, with remaining rep count.
    var unmetExercises: [(exercise: ExerciseType, remaining: Int)] {
        activeExercises
            .filter { !goalMet(for: $0) }
            .map { ($0, goal(for: $0) - totalReps(for: $0)) }
    }

    func markRestDay(context: ModelContext) {
        context.insert(WorkoutEntry(kind: .rest))
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func freezeToday(context: ModelContext) {
        guard freezeTokens > 0 else { return }
        // Don't spend a token if today already qualifies — a workout was logged.
        guard todaysEntries.filter({ $0.kind == .workout }).isEmpty else { return }
        let today = StreakEngine.logicalDay(for: .now)
        let todayDate = Calendar.current.date(from: today)!
        let entryTime = Calendar.current.date(
            bySettingHour: StreakEngine.rolloverHour + 1, minute: 0, second: 0, of: todayDate
        )!
        context.insert(WorkoutEntry(timestamp: entryTime, kind: .freeze))
        freezeTokens -= 1
        saveFreezeState()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func useFreeze(context: ModelContext) {
        guard freezeTokens > 0 else { return }
        let yesterday = StreakEngine.previousLogicalDay(before: StreakEngine.logicalDay(for: .now))
        let yesterdayDate = Calendar.current.date(from: yesterday)!
        let entryTime = Calendar.current.date(
            bySettingHour: StreakEngine.rolloverHour + 1, minute: 0, second: 0, of: yesterdayDate
        )!
        context.insert(WorkoutEntry(timestamp: entryTime, kind: .freeze))
        freezeTokens -= 1
        saveFreezeState()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func awardFreezeTokenIfEarned() {
        let streak = loggedStreak
        guard streak > 0 && streak % 7 == 0 else { return }
        let todayKey = dayKey(StreakEngine.logicalDay(for: .now))
        let lastAwardedDay = Self.sharedDefaults.string(forKey: Self.lastFreezeAwardDayKey) ?? ""
        guard todayKey != lastAwardedDay else { return }
        Self.sharedDefaults.set(todayKey, forKey: Self.lastFreezeAwardDayKey)
        guard freezeTokens < 2 else { return }
        freezeTokens += 1
        saveFreezeState()
    }

    // MARK: - Eulogy

    private func checkEulogy() {
        guard loggedStreak == 0, pendingEulogy == nil else { return }
        guard let (length, endDay) = StreakEngine.lastCompletedStreak(entries: allEntries),
              length >= 7 else { return }
        let endDayKey = dayKey(endDay)
        let shownForDay = Self.sharedDefaults.string(forKey: Self.eulogyShownForDayKey) ?? ""
        guard endDayKey != shownForDay else { return }
        pendingEulogy = length
    }

    func dismissEulogy() {
        guard let (_, endDay) = StreakEngine.lastCompletedStreak(entries: allEntries) else { return }
        Self.sharedDefaults.set(dayKey(endDay), forKey: Self.eulogyShownForDayKey)
        pendingEulogy = nil
    }

    private func saveFreezeState() {
        Self.sharedDefaults.set(freezeTokens, forKey: Self.freezeTokensKey)
    }

    // MARK: - Persistence

    private static let appGroupID = "group.com.rylanddean.justreps"
    private static let exercisesKey = "activeExercises"
    private static let goalsKey = "dailyGoals"
    private static let mvrKey = "minimumViableReps"
    private static let mvrEffectiveDateKey = "mvrEffectiveDate"
    private static let completedGoalDaysKey = "completedGoalDays"
    private static let freezeTokensKey = "freezeTokens"
    private static let lastFreezeAwardDayKey = "lastFreezeAwardDay"
    private static let eulogyShownForDayKey = "eulogyShownForDay"
    static let walkingStepsTodayKey = "walkingStepsToday"
    static let currentRepStreakKey = "currentRepStreak"
    static let currentGoalsStreakKey = "currentGoalsStreak"
    static let widgetHeatmapKey = "widgetHeatmap"

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

    private func saveMVR() {
        Self.sharedDefaults.set(minimumViableReps, forKey: Self.mvrKey)
    }

    private static func loadMVR() -> [String: Int] {
        (sharedDefaults.dictionary(forKey: mvrKey) as? [String: Int]) ?? [:]
    }

    private var mvrEffectiveDate: Date? {
        get {
            let ti = Self.sharedDefaults.double(forKey: Self.mvrEffectiveDateKey)
            return ti > 0 ? Date(timeIntervalSinceReferenceDate: ti) : nil
        }
        set {
            Self.sharedDefaults.set(
                newValue.map { $0.timeIntervalSinceReferenceDate } ?? 0,
                forKey: Self.mvrEffectiveDateKey
            )
        }
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
        case .squats:     return 50
        case .stretching: return 1
        case .walking:    return 8_000
        default:          return 25
        }
    }
}
