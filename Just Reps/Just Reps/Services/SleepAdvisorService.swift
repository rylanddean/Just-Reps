import Foundation
import HealthKit

struct SleepAdvisorService {

    // Threshold: below 5.5 hours of sleep = poor night
    static let minimumSleepHours: Double = 5.5

    private static let store = HKHealthStore()
    private static let dismissedDateKey = "sleep.restSuggestionDismissedDate"

    /// Returns true if last night's sleep was below the threshold and the user hasn't
    /// already dismissed the suggestion today. Requests HealthKit read permission the
    /// first time it runs; subsequent calls are silent if permission is already decided.
    static func shouldSuggestRestDay() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard !alreadyDismissedToday() else { return false }

        let sleepType = HKCategoryType(.sleepAnalysis)
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
        } catch {
            return false
        }

        let hours = await fetchLastNightSleepHours()
        return hours > 0 && hours < minimumSleepHours
    }

    /// Records that the suggestion was shown/dismissed today — suppresses it for the rest of the day.
    static func dismissForToday() {
        UserDefaults.standard.set(todayKey(), forKey: dismissedDateKey)
    }

    static func alreadyDismissedToday() -> Bool {
        UserDefaults.standard.string(forKey: dismissedDateKey) == todayKey()
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    // MARK: - HealthKit query

    private static func fetchLastNightSleepHours() async -> Double {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        // Window: 6 PM yesterday → 10 AM today — captures a typical night's sleep.
        guard let windowStart = calendar.date(byAdding: .hour, value: -18, to: todayStart),
              let windowEnd = calendar.date(byAdding: .hour, value: 10, to: todayStart)
        else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKCategoryType(.sleepAnalysis),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: results as? [HKCategorySample] ?? [])
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue
        ]

        let totalSeconds = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        return totalSeconds / 3600
    }
}
