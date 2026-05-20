import HealthKit

struct TrainingLoadSummary {
    let todayMinutes: Int
    let weeklyMinutes: Int
    let trend: Trend

    enum Trend: Equatable {
        case up, neutral, down

        var arrowSymbol: String {
            switch self {
            case .up:      return "arrow.up.right"
            case .down:    return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
}

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var trainingLoad: TrainingLoadSummary? = nil

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        guard isAvailable else { return }
        isAuthorized = store.authorizationStatus(for: .workoutType()) == .sharingAuthorized
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(
                toShare: [.workoutType(), HKQuantityType(.activeEnergyBurned)],
                read: [HKQuantityType(.appleExerciseTime)]
            )
            checkAuthorization()
        } catch {
            // authorization failed
        }
        return isAuthorized
    }

    /// Logs a strength training workout to HealthKit for exercise ring credit.
    /// Plank reps are treated as seconds of hold; all others use repsPerMinute.
    func logWorkout(exercise: ExerciseType, reps: Int, repsPerMinute: Int, effort: WorkoutEffort?) async {
        guard isAuthorized, reps > 0 else { return }

        let durationSeconds: TimeInterval
        switch exercise {
        case .plank:
            durationSeconds = Double(reps)
        case .stretching:
            durationSeconds = Double(reps) * 600  // 10 min per session
        default:
            durationSeconds = (Double(reps) / Double(max(1, repsPerMinute))) * 60
        }
        guard durationSeconds >= 1 else { return }

        let end = Date()
        let start = end.addingTimeInterval(-durationSeconds)

        let config = HKWorkoutConfiguration()
        config.activityType = {
            if case .stretching = exercise { return .flexibility }
            return .traditionalStrengthTraining
        }()

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)

            // Active energy is required for the workout to count toward the Exercise ring
            let kcalPerMinute: Double = config.activityType == .flexibility ? 2.5 : 5.0
            let kcal = max(1.0, (durationSeconds / 60.0) * kcalPerMinute)
            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])

            if let effort {
                // workoutEffortScore requires a private HealthKit unit, so store as metadata
                await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                    builder.addMetadata([
                        "RPEScore": effort.rpeValue,
                        "EffortLabel": effort.label
                    ]) { _, _ in c.resume() }
                }
            }
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // ring credit is a bonus feature — fail silently
        }
    }

    // MARK: - Delete

    func deleteWorkout(near timestamp: Date) async {
        guard isAuthorized else { return }

        let timePredicate = HKQuery.predicateForSamples(
            withStart: timestamp.addingTimeInterval(-10),
            end: timestamp.addingTimeInterval(10)
        )
        let activityPredicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, activityPredicate])
        let samplePredicate = HKSamplePredicate<HKWorkout>.workout(compound)

        let descriptor = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [])
        guard let workouts = try? await descriptor.result(for: store), !workouts.isEmpty else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.delete(workouts) { _, _ in continuation.resume() }
        }
    }

    // MARK: - Training Load

    func fetchTrainingLoad() async {
        guard isAvailable else { return }
        // If the user already enabled HealthKit for workouts, request exercise-time read
        // in the same call. HealthKit only shows the dialog for types not yet decided.
        if isAuthorized { _ = await requestAuthorization() }

        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!
        let priorStart = calendar.date(byAdding: .day, value: -13, to: todayStart)!
        let priorEnd = calendar.date(byAdding: .day, value: -7, to: todayStart)!

        async let todayMins = fetchExerciseMinutes(from: todayStart, to: now)
        async let weekMins = fetchExerciseMinutes(from: weekStart, to: now)
        async let priorMins = fetchExerciseMinutes(from: priorStart, to: priorEnd)

        let (today, week, prior) = await (todayMins, weekMins, priorMins)

        let trend: TrainingLoadSummary.Trend
        if prior == 0 {
            trend = .neutral
        } else if week > Int(Double(prior) * 1.1) {
            trend = .up
        } else if week < Int(Double(prior) * 0.9) {
            trend = .down
        } else {
            trend = .neutral
        }

        trainingLoad = TrainingLoadSummary(todayMinutes: today, weeklyMinutes: week, trend: trend)

        // Share with Watch via App Group
        let shared = UserDefaults(suiteName: "group.com.rylanddean.justreps") ?? .standard
        shared.set(today, forKey: "trainingLoadTodayMins")
        shared.set(week, forKey: "trainingLoadWeeklyMins")
        shared.set(trend == .up ? "up" : trend == .down ? "down" : "neutral", forKey: "trainingLoadTrend")
    }

    private func fetchExerciseMinutes(from start: Date, to end: Date) async -> Int {
        let type = HKQuantityType(.appleExerciseTime)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let minutes = stats?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                continuation.resume(returning: Int(minutes))
            }
            store.execute(query)
        }
    }
}
