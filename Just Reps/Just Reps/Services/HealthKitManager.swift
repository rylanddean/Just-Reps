import HealthKit

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private(set) var isAuthorized = false

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
            try await store.requestAuthorization(toShare: [.workoutType()], read: [])
            checkAuthorization()
        } catch {
            // authorization failed
        }
        return isAuthorized
    }

    /// Logs a strength training workout to HealthKit for exercise ring credit.
    /// Plank reps are treated as seconds of hold; all others use repsPerMinute.
    func logWorkout(exercise: ExerciseType, reps: Int, repsPerMinute: Int) async {
        guard isAuthorized, reps > 0 else { return }

        let durationSeconds: TimeInterval
        if case .plank = exercise {
            durationSeconds = Double(reps)
        } else {
            durationSeconds = (Double(reps) / Double(max(1, repsPerMinute))) * 60
        }
        guard durationSeconds >= 1 else { return }

        let end = Date()
        let start = end.addingTimeInterval(-durationSeconds)

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // ring credit is a bonus feature — fail silently
        }
    }
}
