import Foundation
import SwiftData

@Model
final class CustomMilestone {
    var id: UUID
    var title: String
    var metricType: String   // "repStreak" | "goalStreak" | "totalReps"
    var exerciseRaw: String? // only set for totalReps
    var target: Int
    var createdAt: Date

    init(title: String, metricType: String, exerciseRaw: String? = nil, target: Int) {
        id = UUID()
        self.title = title
        self.metricType = metricType
        self.exerciseRaw = exerciseRaw
        self.target = target
        createdAt = .now
    }
}
