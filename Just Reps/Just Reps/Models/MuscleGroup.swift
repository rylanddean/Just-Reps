enum MuscleGroup: String, CaseIterable, Hashable, Codable {
    case upper
    case back
    case arms
    case core
    case legs
    case glutes

    var displayName: String {
        switch self {
        case .upper:  return "Upper"
        case .back:   return "Back"
        case .arms:   return "Arms"
        case .core:   return "Core"
        case .legs:   return "Legs"
        case .glutes: return "Glutes"
        }
    }
}
