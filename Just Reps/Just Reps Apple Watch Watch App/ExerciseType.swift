import Foundation
import SwiftData

// Built-in exercise types — custom exercises stored as `.custom(name:)`
enum ExerciseType: Codable, Hashable, Identifiable {
    case pushups
    case squats
    case plank        // reps here = seconds
    case pullups
    case situps
    case stretching   // counts sessions, not reps
    case custom(name: String)

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .pushups:          return "Pushups"
        case .squats:           return "Squats"
        case .plank:            return "Plank"
        case .pullups:          return "Pullups"
        case .situps:           return "Situps"
        case .stretching:       return "Stretching"
        case .custom(let name): return name
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
        case .custom:     return "⚡️"
        }
    }

    var unit: String {
        switch self {
        case .plank:      return "sec"
        case .stretching: return "sessions"
        default:          return "reps"
        }
    }

    var quickIncrements: [Int] {
        switch self {
        case .plank:      return [10, 30, 60]
        case .stretching: return [1]
        default:          return [5, 10, 25]
        }
    }

    var rawString: String {
        switch self {
        case .pushups:          return "pushups"
        case .squats:           return "squats"
        case .plank:            return "plank"
        case .pullups:          return "pullups"
        case .situps:           return "situps"
        case .stretching:       return "stretching"
        case .custom(let name): return "custom:\(name)"
        }
    }

    init(rawString: String) {
        if rawString.hasPrefix("custom:") {
            self = .custom(name: String(rawString.dropFirst(7)))
        } else {
            switch rawString {
            case "squats":     self = .squats
            case "plank":      self = .plank
            case "pullups":    self = .pullups
            case "situps":     self = .situps
            case "stretching": self = .stretching
            default:           self = .pushups
            }
        }
    }

    static var defaults: [ExerciseType] { [.pushups, .squats] }
}
