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

// MARK: - WatchConnectivity serialization

extension WorkoutEntry {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "exerciseRaw": exerciseRaw,
            "reps": reps,
            "timestamp": timestamp.timeIntervalSinceReferenceDate
        ]
        if let rpe = effortRPE { dict["effortRPE"] = rpe }
        if let k = kindRaw { dict["kindRaw"] = k }
        return dict
    }

    static func from(dictionary dict: [String: Any]) -> WorkoutEntry? {
        guard
            let idStr = dict["id"] as? String,
            let uuid = UUID(uuidString: idStr),
            let exerciseRaw = dict["exerciseRaw"] as? String,
            let reps = dict["reps"] as? Int,
            let ts = dict["timestamp"] as? TimeInterval
        else { return nil }
        let entry = WorkoutEntry(
            exercise: ExerciseType(rawString: exerciseRaw),
            reps: reps,
            timestamp: Date(timeIntervalSinceReferenceDate: ts),
            effortRPE: dict["effortRPE"] as? Double,
            kind: EntryKind(rawValue: dict["kindRaw"] as? String ?? "") ?? .workout
        )
        entry.id = uuid
        return entry
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
