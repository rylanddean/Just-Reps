import Foundation
import SwiftData

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
// Note: muscleGroups are not stored on Watch; trackingType is parsed from the shared rawString format.
enum ExerciseType: Codable, Hashable, Identifiable {
    case pushups
    case squats
    case plank        // reps here = seconds
    case pullups
    case situps
    case stretching   // counts sessions, not reps
    case walking      // steps, auto-tracked from Apple Health on iPhone
    case custom(name: String, trackingType: TrackingType = .reps)

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .pushups:             return "Pushups"
        case .squats:              return "Squats"
        case .plank:               return "Plank"
        case .pullups:             return "Pullups"
        case .situps:              return "Situps"
        case .stretching:          return "Stretching"
        case .walking:             return "Walking"
        case .custom(let name, _): return name
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

    var unit: String {
        switch self {
        case .plank:      return "sec"
        case .stretching: return "sessions"
        case .walking:    return "steps"
        case .custom(_, let trackingType):
            switch trackingType {
            case .reps:     return "reps"
            case .seconds:  return "sec"
            case .sessions: return "sessions"
            }
        default: return "reps"
        }
    }

    var isTimerBased: Bool {
        switch self {
        case .plank:                        return true
        case .custom(_, let trackingType):  return trackingType == .seconds
        default:                            return false
        }
    }

    var isAutoTracked: Bool {
        if case .walking = self { return true }
        return false
    }

    var quickIncrements: [Int] {
        switch self {
        case .plank:      return [10, 30, 60]
        case .stretching: return [1]
        case .walking:    return []
        case .custom(_, let trackingType):
            switch trackingType {
            case .reps:     return [5, 10, 25]
            case .seconds:  return [10, 30, 60]
            case .sessions: return [1]
            }
        default: return [5, 10, 25]
        }
    }

    // Mirrors the iOS rawString format. muscleGroups segment (index 1) is omitted on Watch
    // but preserved during round-trips because exerciseRaw is set from the phone's original string.
    var rawString: String {
        switch self {
        case .pushups:    return "pushups"
        case .squats:     return "squats"
        case .plank:      return "plank"
        case .pullups:    return "pullups"
        case .situps:     return "situps"
        case .stretching: return "stretching"
        case .walking:    return "walking"
        case .custom(let name, let trackingType):
            guard trackingType != .reps else { return "custom:\(name)" }
            return "custom:\(name)||\(trackingType.rawValue)"
        }
    }

    init(rawString: String) {
        if rawString.hasPrefix("custom:") {
            let remainder = String(rawString.dropFirst(7))
            // Format: "name", "name|groups", or "name|groups|trackingType"
            let parts = remainder.components(separatedBy: "|")
            let name = parts[0]
            let trackingType = parts.count >= 3
                ? TrackingType(rawValue: parts[2]) ?? .reps
                : .reps
            self = .custom(name: name, trackingType: trackingType)
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

    static var defaults: [ExerciseType] { [.pushups, .squats] }
}
