import Foundation

struct StreakAnalytics {

    enum Period {
        case weekly
        case monthly

        var bucketCount: Int {
            switch self {
            case .weekly: return 8
            case .monthly: return 6
            }
        }

        fileprivate var calendarComponent: Calendar.Component {
            switch self {
            case .weekly: return .weekOfYear
            case .monthly: return .month
            }
        }
    }

    struct Bucket: Identifiable {
        let start: Date
        let end: Date
        let daysInPeriod: Int
        let totalsByExercise: [ExerciseType: Int]

        var id: Date { start }

        func totalReps(for exercise: ExerciseType) -> Int {
            totalsByExercise[exercise, default: 0]
        }

        func average(for exercise: ExerciseType) -> Double {
            guard daysInPeriod > 0 else { return 0 }
            return Double(totalReps(for: exercise)) / Double(daysInPeriod)
        }
    }

    struct Summary: Identifiable {
        let exercise: ExerciseType
        let average: Double

        var id: String { exercise.rawString }
    }

    struct ChartPoint: Identifiable {
        let exercise: ExerciseType
        let date: Date
        let average: Double

        var id: String { "\(exercise.rawString)-\(date.timeIntervalSinceReferenceDate)" }
    }

    static func averageBuckets(
        entries: [WorkoutEntry],
        period: Period,
        count: Int? = nil,
        referenceDate: Date = .now
    ) -> [Bucket] {
        let calendar = Calendar.current
        let bucketCount = max(count ?? period.bucketCount, 1)

        guard
            let referenceLogicalDay = calendar.date(from: StreakEngine.logicalDay(for: referenceDate)),
            let referenceAnchor = calendar.dateInterval(of: period.calendarComponent, for: referenceLogicalDay)?.start
        else {
            return []
        }

        let logicalEntries = entries.compactMap { entry -> (date: Date, exercise: ExerciseType, reps: Int)? in
            let logicalDay = StreakEngine.logicalDay(for: entry.timestamp)
            guard let dayDate = calendar.date(from: logicalDay) else { return nil }
            return (date: dayDate, exercise: entry.exercise, reps: entry.reps)
        }

        let bucketStarts: [Date] = (0..<bucketCount).compactMap { offset in
            calendar.date(byAdding: period.calendarComponent, value: -offset, to: referenceAnchor)
        }.reversed()

        return bucketStarts.compactMap { start in
            guard let end = calendar.date(byAdding: period.calendarComponent, value: 1, to: start) else {
                return nil
            }

            let daysInPeriod: Int
            if start == referenceAnchor {
                let elapsedDays = calendar.dateComponents([.day], from: start, to: referenceLogicalDay).day ?? 0
                daysInPeriod = max(elapsedDays + 1, 1)
            } else {
                daysInPeriod = period == .weekly
                    ? 7
                    : max(calendar.range(of: .day, in: .month, for: start)?.count ?? 0, 1)
            }

            var totalsByExercise: [ExerciseType: Int] = [:]
            for entry in logicalEntries where entry.date >= start && entry.date < end {
                totalsByExercise[entry.exercise, default: 0] += entry.reps
            }

            return Bucket(
                start: start,
                end: end,
                daysInPeriod: daysInPeriod,
                totalsByExercise: totalsByExercise
            )
        }
    }

    static func summaries(
        entries: [WorkoutEntry],
        period: Period,
        referenceDate: Date = .now
    ) -> [Summary] {
        let buckets = averageBuckets(entries: entries, period: period, referenceDate: referenceDate)
        let exercises = visibleExercises(in: buckets)

        return exercises.map { exercise in
            let totalReps = buckets.reduce(0) { $0 + $1.totalReps(for: exercise) }
            let totalDays = buckets.reduce(0) { $0 + $1.daysInPeriod }
            let average = totalDays > 0 ? Double(totalReps) / Double(totalDays) : 0
            return Summary(exercise: exercise, average: average)
        }
    }

    static func chartPoints(
        entries: [WorkoutEntry],
        period: Period,
        referenceDate: Date = .now
    ) -> [ChartPoint] {
        let buckets = averageBuckets(entries: entries, period: period, referenceDate: referenceDate)
        let exercises = visibleExercises(in: buckets)

        return exercises.flatMap { exercise in
            buckets.map { bucket in
                ChartPoint(
                    exercise: exercise,
                    date: bucket.start,
                    average: bucket.average(for: exercise)
                )
            }
        }
        .sorted {
            if $0.date == $1.date {
                return $0.exercise.displayName.localizedCaseInsensitiveCompare($1.exercise.displayName) == .orderedAscending
            }
            return $0.date < $1.date
        }
    }

    static func visibleExercises(in buckets: [Bucket]) -> [ExerciseType] {
        let activeExercises = Set(
            buckets.flatMap { bucket in
                bucket.totalsByExercise
                    .filter { $0.value > 0 }
                    .map { $0.key }
            }
        )

        return activeExercises.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
}
