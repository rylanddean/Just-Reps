import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var id: UUID
    // Store as raw string since SwiftData can't store custom enums natively
    var exerciseRaw: String
    var reps: Int
    var timestamp: Date

    init(exercise: ExerciseType, reps: Int, timestamp: Date = .now) {
        self.id = UUID()
        self.exerciseRaw = exercise.rawString
        self.reps = reps
        self.timestamp = timestamp
    }

    var exercise: ExerciseType {
        ExerciseType(rawString: exerciseRaw)
    }
}

// MARK: - Convenience queries

extension WorkoutEntry {
    static func todaysPredicate() -> Predicate<WorkoutEntry> {
        let bounds = StreakEngine.logicalDayBounds(for: .now)
        let start = bounds.start
        let end = bounds.end
        return #Predicate<WorkoutEntry> { entry in
            entry.timestamp >= start && entry.timestamp < end
        }
    }

    static func predicate(for date: Date) -> Predicate<WorkoutEntry> {
        let bounds = StreakEngine.logicalDayBounds(for: date)
        let start = bounds.start
        let end = bounds.end
        return #Predicate<WorkoutEntry> { entry in
            entry.timestamp >= start && entry.timestamp < end
        }
    }
}
