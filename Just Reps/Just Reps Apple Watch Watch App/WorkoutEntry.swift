import Foundation
import SwiftData

enum EntryKind: String {
    case workout, rest, freeze
}

@Model
final class WorkoutEntry {
    var id: UUID
    // Store as raw string since SwiftData can't store custom enums natively
    var exerciseRaw: String
    var reps: Int
    var timestamp: Date
    var effortRPE: Double?
    // nil means .workout — backward-compatible with existing rows
    var kindRaw: String?

    init(exercise: ExerciseType = .pushups, reps: Int = 0, timestamp: Date = .now, effortRPE: Double? = nil, kind: EntryKind = .workout) {
        self.id = UUID()
        self.exerciseRaw = exercise.rawString
        self.reps = reps
        self.timestamp = timestamp
        self.effortRPE = effortRPE
        self.kindRaw = kind == .workout ? nil : kind.rawValue
    }

    var exercise: ExerciseType {
        ExerciseType(rawString: exerciseRaw)
    }

    var kind: EntryKind {
        EntryKind(rawValue: kindRaw ?? "") ?? .workout
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
