import Foundation
import SwiftData

// MARK: - Walking unit preference

enum WalkingUnit: String, CaseIterable {
    case steps, km, mi

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .km:    return "Kilometers"
        case .mi:    return "Miles"
        }
    }

    var unitLabel: String { rawValue }   // "steps" / "km" / "mi"

    /// Default daily goal stored in internal integer units.
    var defaultGoal: Int {
        switch self {
        case .steps: return 8_000
        case .km:    return 50   // 5.0 km  (stored × 10)
        case .mi:    return 30   // 3.0 mi  (stored × 10)
        }
    }

    static var current: WalkingUnit {
        let raw = UserDefaults(suiteName: "group.com.rylanddean.justreps")?.string(forKey: "walkingUnit") ?? "steps"
        return WalkingUnit(rawValue: raw) ?? .steps
    }
}

// MARK: - TrackingType

enum TrackingType: String, CaseIterable, Codable {
    case reps
    case seconds
    case sessions

    var displayName: String {
        switch self {
        case .reps:     return "Reps"
        case .seconds:  return "Seconds"
        case .sessions: return "Sessions"
        }
    }
}

// Built-in exercise types — custom exercises stored as `.custom(name:)`
enum ExerciseType: Codable, Hashable, Identifiable {
    case pushups
    case squats
    case plank        // reps here = seconds
    case pullups
    case situps
    case stretching   // counts sessions, not reps
    case walking      // steps, auto-tracked from Apple Health
    case custom(name: String, muscleGroups: [MuscleGroup] = [], trackingType: TrackingType = .reps)

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .pushups:    return "Pushups"
        case .squats:     return "Squats"
        case .plank:      return "Plank"
        case .pullups:    return "Pullups"
        case .situps:     return "Situps"
        case .stretching: return "Stretching"
        case .walking:    return "Walking"
        case .custom(let name, _, _): return name
        }
    }

    var emoji: String {
        switch self {
        case .pushups:    return "💪"
        case .squats:     return "🦵"
        case .plank:      return "🧘"
        case .pullups:    return "🏋️"
        case .situps:     return "🔥"
        case .stretching: return "🤸"
        case .walking:    return "🚶"
        case .custom:     return "⚡️"
        }
    }

    // Unit label shown next to rep count
    var unit: String {
        switch self {
        case .plank:      return "sec"
        case .stretching: return "sessions"
        case .walking:    return WalkingUnit.current.unitLabel
        case .custom(_, _, let trackingType):
            switch trackingType {
            case .reps:     return "reps"
            case .seconds:  return "sec"
            case .sessions: return "sessions"
            }
        default: return "reps"
        }
    }

    var muscleGroups: [MuscleGroup] {
        switch self {
        case .pushups:    return [.upper, .arms]
        case .squats:     return [.legs, .glutes]
        case .plank:      return [.core]
        case .pullups:    return [.back, .arms]
        case .situps:     return [.core]
        case .stretching: return []
        case .walking:    return [.legs]
        case .custom(_, let groups, _): return groups
        }
    }

    var isTimerBased: Bool {
        switch self {
        case .plank: return true
        case .custom(_, _, let trackingType): return trackingType == .seconds
        default: return false
        }
    }

    /// True for exercises whose count is pulled from Apple Health automatically
    /// rather than logged by tapping. These show a "Synced from Health" card UI.
    var isAutoTracked: Bool {
        if case .walking = self { return true }
        return false
    }

    /// True when the stored integer value should be displayed with one decimal place
    /// (distance modes store value × 10 to preserve precision in an Int).
    var usesDecimalDisplay: Bool {
        if case .walking = self { return WalkingUnit.current != .steps }
        return false
    }

    /// Human-readable string for a stored integer value.
    /// For distance walking, divides by 10 to recover one decimal place.
    func formattedValue(_ n: Int) -> String {
        if usesDecimalDisplay { return String(format: "%.1f", Double(n) / 10.0) }
        return "\(n)"
    }

    // Default quick-add increments
    var quickIncrements: [Int] {
        switch self {
        case .plank:      return [10, 30, 60]
        case .stretching: return [1]
        case .walking:    return []   // auto-tracked — not tapped manually
        case .custom(_, _, let trackingType):
            switch trackingType {
            case .reps:     return [5, 10, 25]
            case .seconds:  return [10, 30, 60]
            case .sessions: return [1]
            }
        default: return [5, 10, 25]
        }
    }

    // Codable support for SwiftData serialisation via rawValue string
    // Format: "custom:name", "custom:name|upper,core", or "custom:name|upper,core|seconds"
    var rawString: String {
        switch self {
        case .pushups:    return "pushups"
        case .squats:     return "squats"
        case .plank:      return "plank"
        case .pullups:    return "pullups"
        case .situps:     return "situps"
        case .stretching: return "stretching"
        case .walking:    return "walking"
        case .custom(let name, let groups, let trackingType):
            var result = "custom:\(name)"
            if !groups.isEmpty || trackingType != .reps {
                result += "|" + groups.map(\.rawValue).joined(separator: ",")
            }
            if trackingType != .reps {
                result += "|\(trackingType.rawValue)"
            }
            return result
        }
    }

    init(rawString: String) {
        if rawString.hasPrefix("custom:") {
            let remainder = String(rawString.dropFirst(7))
            let parts = remainder.components(separatedBy: "|")
            let name = parts[0]
            let groups = parts.count >= 2
                ? parts[1].split(separator: ",").compactMap { MuscleGroup(rawValue: String($0)) }
                : []
            let trackingType = parts.count >= 3
                ? TrackingType(rawValue: parts[2]) ?? .reps
                : .reps
            self = .custom(name: name, muscleGroups: groups, trackingType: trackingType)
        } else {
            switch rawString {
            case "squats":     self = .squats
            case "plank":      self = .plank
            case "pullups":    self = .pullups
            case "situps":     self = .situps
            case "stretching": self = .stretching
            case "walking":    self = .walking
            default:           self = .pushups
            }
        }
    }

    // Default exercises shown on Home when no custom list is set
    static var defaults: [ExerciseType] { [.pushups, .squats] }
}
