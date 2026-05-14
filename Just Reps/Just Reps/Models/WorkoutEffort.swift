enum WorkoutEffort: CaseIterable {
    case easy, moderate, hard, allOut

    var label: String {
        switch self {
        case .easy:     return "Easy"
        case .moderate: return "Moderate"
        case .hard:     return "Hard"
        case .allOut:   return "All Out"
        }
    }

    var rpeRange: String {
        switch self {
        case .easy:     return "1–3"
        case .moderate: return "3–6"
        case .hard:     return "7–8"
        case .allOut:   return "9–10"
        }
    }

    // Midpoint of each range, used as the HKQuantity value
    var rpeValue: Double {
        switch self {
        case .easy:     return 2.0
        case .moderate: return 5.0
        case .hard:     return 7.5
        case .allOut:   return 9.5
        }
    }
}
