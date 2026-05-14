import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let emoji: String

    // Condition evaluated against app state; keeping it simple with value-based checks
    enum Condition {
        case streakReached(Int)
        case totalRepsReached(exercise: String, count: Int)
        case neverMissedWeekday(Int) // 0=Sun … 6=Sat
    }

    let condition: Condition

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }

    // MARK: - All achievements

    static let all: [Achievement] = [
        Achievement(
            id: "first_week",
            title: "First Week",
            description: "Maintained a 7-day streak.",
            emoji: "🗓",
            condition: .streakReached(7)
        ),
        Achievement(
            id: "thirty_days",
            title: "30 Days",
            description: "Maintained a 30-day streak.",
            emoji: "🔥",
            condition: .streakReached(30)
        ),
        Achievement(
            id: "hundred_days",
            title: "100 Days",
            description: "Maintained a 100-day streak.",
            emoji: "💯",
            condition: .streakReached(100)
        ),
        Achievement(
            id: "1000_pushups",
            title: "1000 Pushups",
            description: "Logged 1,000 total pushups.",
            emoji: "💪",
            condition: .totalRepsReached(exercise: "pushups", count: 1000)
        ),
        Achievement(
            id: "1000_squats",
            title: "1000 Squats",
            description: "Logged 1,000 total squats.",
            emoji: "🦵",
            condition: .totalRepsReached(exercise: "squats", count: 1000)
        ),
        Achievement(
            id: "never_missed_monday",
            title: "Never Missed a Monday",
            description: "Worked out every Monday for 4 weeks straight.",
            emoji: "📅",
            condition: .neverMissedWeekday(2) // Monday = weekday 2
        ),
        Achievement(
            id: "tiny_gains",
            title: "Tiny Gains",
            description: "Logged your first workout.",
            emoji: "⚡️",
            condition: .streakReached(1)
        ),
    ]
}
