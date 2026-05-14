import Foundation

struct GoalRecommendation {
    let exercise: ExerciseType
    let currentGoal: Int
    let suggestedGoal: Int
    let direction: Direction

    enum Direction {
        case increase, decrease
    }

    var headline: String {
        switch direction {
        case .increase: return "Here's a goal that fits your week."
        case .decrease: return "Ease into it."
        }
    }
}

struct GoalAdvisorService {

    /// Returns per-exercise goal recommendations based on the last 7 completed days.
    /// Requires at least 4 days of activity per exercise before making a suggestion.
    static func recommendations(
        for exercises: [ExerciseType],
        goals: [String: Int],
        entries: [WorkoutEntry],
        trainingLoad: TrainingLoadSummary?
    ) -> [GoalRecommendation] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)

        // Build the 7 most recently completed calendar days
        let dayStarts: [Date] = (1...7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: todayStart)
        }

        var recs: [GoalRecommendation] = []

        for exercise in exercises {
            guard exercise != .stretching else { continue }
            let goal = goals[exercise.rawString] ?? defaultGoal(for: exercise)
            var daysWithActivity = 0
            var daysGoalMet = 0
            var rpeValues: [Double] = []

            for dayStart in dayStarts {
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                let dayEntries = entries.filter {
                    $0.exercise == exercise &&
                    $0.timestamp >= dayStart &&
                    $0.timestamp < dayEnd
                }
                guard !dayEntries.isEmpty else { continue }
                daysWithActivity += 1

                let totalReps = dayEntries.reduce(0) { $0 + $1.reps }
                if totalReps >= goal { daysGoalMet += 1 }

                rpeValues.append(contentsOf: dayEntries.compactMap { $0.effortRPE })
            }

            guard daysWithActivity >= 4 else { continue }

            let avgRPE = rpeValues.isEmpty ? nil : rpeValues.reduce(0, +) / Double(rpeValues.count)
            let loadTrend = trainingLoad?.trend

            let shouldIncrease = daysGoalMet >= 6
                && (avgRPE == nil || avgRPE! <= 5.0)
                && loadTrend != .up

            let shouldDecrease = daysGoalMet <= 3
                || (avgRPE != nil && avgRPE! >= 7.5 && daysGoalMet < 5)
                || (loadTrend == .up && avgRPE != nil && avgRPE! >= 7.5)

            if shouldIncrease {
                let suggested = roundToNearest5(Int(Double(goal) * 1.15))
                guard suggested != goal else { continue }
                recs.append(GoalRecommendation(
                    exercise: exercise, currentGoal: goal,
                    suggestedGoal: suggested, direction: .increase
                ))
            } else if shouldDecrease {
                let suggested = max(5, roundToNearest5(Int(Double(goal) * 0.85)))
                guard suggested != goal else { continue }
                recs.append(GoalRecommendation(
                    exercise: exercise, currentGoal: goal,
                    suggestedGoal: suggested, direction: .decrease
                ))
            }
        }

        return recs
    }

    private static func roundToNearest5(_ value: Int) -> Int {
        Int((Double(value) / 5.0).rounded()) * 5
    }

    private static func defaultGoal(for exercise: ExerciseType) -> Int {
        switch exercise {
        case .squats:     return 50
        case .stretching: return 1
        default:          return 25
        }
    }
}
