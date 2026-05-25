import Foundation
import WatchConnectivity
import SwiftData

final class PhoneSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()
    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // Push current state to watch. Called whenever iOS entries, exercises, goals, or MVR change.
    func pushContext(entries: [WorkoutEntry], exercises: [ExerciseType], goals: [String: Int], mvr: [String: Int] = [:], mvrEffectiveDate: Date? = nil) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isPaired,
              WCSession.default.isWatchAppInstalled else { return }
        let cutoff = Date(timeIntervalSinceNow: -90 * 86400)
        let recent = entries.filter { $0.timestamp >= cutoff }
        var payload: [String: Any] = [
            "entries": recent.map { $0.toDictionary() },
            "exercises": exercises.map { $0.rawString },
            "goals": goals,
            "mvr": mvr
        ]
        if let date = mvrEffectiveDate {
            payload["mvrEffectiveDate"] = date.timeIntervalSinceReferenceDate
        }
        try? WCSession.default.updateApplicationContext(payload)
    }

    // MARK: - WCSessionDelegate (iOS-required stubs)

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        guard state == .activated else { return }
        // Push immediately after activation so the watch gets data even if the initial
        // refresh() call happened before the session was ready.
        DispatchQueue.main.async {
            self.pushUpdatedContext(ctx: sharedModelContainer.mainContext)
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    // Watch logged a rep via sendMessage (phone in range)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        insertEntryFromWatch(message)
    }

    // Watch logged a rep via transferUserInfo (queued delivery when out of range)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        insertEntryFromWatch(userInfo)
    }

    // MARK: - Private

    private func insertEntryFromWatch(_ dict: [String: Any]) {
        guard
            let entryDict = dict["entry"] as? [String: Any],
            let idStr = entryDict["id"] as? String,
            let uuid = UUID(uuidString: idStr)
        else { return }

        DispatchQueue.main.async {
            let ctx = sharedModelContainer.mainContext
            // Deduplicate: skip if this UUID already exists
            let idToFind = uuid
            var descriptor = FetchDescriptor<WorkoutEntry>(
                predicate: #Predicate { $0.id == idToFind }
            )
            descriptor.fetchLimit = 1
            guard (try? ctx.fetch(descriptor))?.isEmpty == true else { return }

            guard let entry = WorkoutEntry.from(dictionary: entryDict) else { return }
            ctx.insert(entry)
            try? ctx.save()

            // Credit exercise ring on behalf of the Watch entry
            if UserDefaults(suiteName: "group.com.rylanddean.justreps")?.bool(forKey: "healthKitEnabled") == true {
                Task {
                    await HealthKitManager.shared.logWorkout(
                        exercise: entry.exercise,
                        reps: entry.reps,
                        effort: nil,
                        at: entry.timestamp
                    )
                }
            }

            // Push updated context back to watch immediately (handles background case)
            self.pushUpdatedContext(ctx: ctx)
        }
    }

    private func pushUpdatedContext(ctx: ModelContext) {
        let entries = (try? ctx.fetch(FetchDescriptor<WorkoutEntry>())) ?? []
        let ud = UserDefaults(suiteName: "group.com.rylanddean.justreps") ?? .standard
        let exercises = (ud.stringArray(forKey: "activeExercises") ?? ["pushups", "squats"])
            .map { ExerciseType(rawString: $0) }
        let goals = (ud.dictionary(forKey: "dailyGoals") as? [String: Int]) ?? ["pushups": 25, "squats": 50]
        let mvr = (ud.dictionary(forKey: "minimumViableReps") as? [String: Int]) ?? [:]
        let mvrEffectiveDateTI = ud.double(forKey: "mvrEffectiveDate")
        let mvrEffectiveDate: Date? = mvrEffectiveDateTI > 0 ? Date(timeIntervalSinceReferenceDate: mvrEffectiveDateTI) : nil
        pushContext(entries: entries, exercises: exercises, goals: goals, mvr: mvr, mvrEffectiveDate: mvrEffectiveDate)
    }
}
