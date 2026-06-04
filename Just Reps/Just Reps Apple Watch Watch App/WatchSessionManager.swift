import Foundation
import WatchConnectivity

@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() { super.init() }

    private(set) var entries: [WorkoutEntry] = []
    private(set) var exercises: [ExerciseType] = ExerciseType.defaults
    private(set) var goals: [String: Int] = ["pushups": 25, "squats": 50]
    private(set) var minimumViableReps: [String: Int] = [:]
    private(set) var mvrEffectiveDate: Date? = nil
    private(set) var walkingStepsToday: Int = 0
    private(set) var isRefreshing = false

    // Bumped whenever any of the above change so ContentView can react with a single onChange.
    private(set) var lastUpdate: Date = .distantPast

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        loadCached()
    }

    func requestRefresh() {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = ["request": "refreshContext"]

        guard WCSession.default.activationState == .activated else {
            activate()
            return
        }

        isRefreshing = true
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                payload,
                replyHandler: { context in
                    DispatchQueue.main.async {
                        self.apply(context)
                        self.cache(context)
                        self.isRefreshing = false
                    }
                },
                errorHandler: { _ in
                    WCSession.default.transferUserInfo(payload)
                    DispatchQueue.main.async {
                        self.isRefreshing = false
                    }
                }
            )
        } else {
            WCSession.default.transferUserInfo(payload)
            isRefreshing = false
        }
    }

    // Send a newly-logged rep entry to the phone.
    func send(_ entry: WorkoutEntry) {
        let payload: [String: Any] = ["entry": entry.toDictionary()]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        DispatchQueue.main.async { self.apply(context) }
        cache(context)
    }

    // MARK: - Private

    private func apply(_ context: [String: Any]) {
        if let dicts = context["entries"] as? [[String: Any]] {
            entries = dicts.compactMap { WorkoutEntry.from(dictionary: $0) }
        }
        if let raw = context["exercises"] as? [String], !raw.isEmpty {
            exercises = raw.map { ExerciseType(rawString: $0) }
        }
        if let g = context["goals"] as? [String: Int], !g.isEmpty {
            goals = g
        }
        if let m = context["mvr"] as? [String: Int] {
            minimumViableReps = m
        }
        if let ti = context["mvrEffectiveDate"] as? Double {
            mvrEffectiveDate = Date(timeIntervalSinceReferenceDate: ti)
        }
        if let steps = context["walkingStepsToday"] as? Int {
            walkingStepsToday = steps
        }
        lastUpdate = .now
    }

    // MARK: - Cache (Watch-local UserDefaults, survives app restarts)

    private static let suite = "group.com.rylanddean.justreps"

    private func cache(_ context: [String: Any]) {
        let ud = UserDefaults(suiteName: Self.suite) ?? .standard
        if let data = try? JSONSerialization.data(withJSONObject: context["entries"] ?? []) {
            ud.set(data, forKey: "wc_entries")
        }
        if let data = try? JSONSerialization.data(withJSONObject: context["exercises"] ?? []) {
            ud.set(data, forKey: "wc_exercises")
        }
        if let data = try? JSONSerialization.data(withJSONObject: context["goals"] ?? [:]) {
            ud.set(data, forKey: "wc_goals")
        }
        if let data = try? JSONSerialization.data(withJSONObject: context["mvr"] ?? [:]) {
            ud.set(data, forKey: "wc_mvr")
        }
        if let ti = context["mvrEffectiveDate"] as? Double {
            ud.set(ti, forKey: "wc_mvrEffectiveDate")
        }
        if let steps = context["walkingStepsToday"] as? Int {
            ud.set(steps, forKey: "wc_walkingStepsToday")
        }
    }

    private func loadCached() {
        let ud = UserDefaults(suiteName: Self.suite) ?? .standard
        var context: [String: Any] = [:]
        if let data = ud.data(forKey: "wc_entries"),
           let obj = try? JSONSerialization.jsonObject(with: data) {
            context["entries"] = obj
        }
        if let data = ud.data(forKey: "wc_exercises"),
           let obj = try? JSONSerialization.jsonObject(with: data) {
            context["exercises"] = obj
        }
        if let data = ud.data(forKey: "wc_goals"),
           let obj = try? JSONSerialization.jsonObject(with: data) {
            context["goals"] = obj
        }
        if let data = ud.data(forKey: "wc_mvr"),
           let obj = try? JSONSerialization.jsonObject(with: data) {
            context["mvr"] = obj
        }
        let mvrTI = ud.double(forKey: "wc_mvrEffectiveDate")
        if mvrTI > 0 { context["mvrEffectiveDate"] = mvrTI }
        if let steps = ud.object(forKey: "wc_walkingStepsToday") as? Int {
            context["walkingStepsToday"] = steps
        }
        if !context.isEmpty {
            DispatchQueue.main.async { self.apply(context) }
        }
    }
}
