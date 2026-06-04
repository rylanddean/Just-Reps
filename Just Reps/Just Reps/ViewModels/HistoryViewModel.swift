import SwiftUI
import SwiftData

@Observable
final class HistoryViewModel {

    private(set) var allEntries: [WorkoutEntry] = []

    func refresh(with entries: [WorkoutEntry]) {
        allEntries = entries
    }

    // MARK: - Derived

    var groupedByDay: [(date: Date, entries: [WorkoutEntry])] {
        let calendar = Calendar.current
        var groups: [Date: [WorkoutEntry]] = [:]
        for entry in allEntries {
            let day = calendar.date(from: StreakEngine.logicalDay(for: entry.timestamp))!
            groups[day, default: []].append(entry)
        }
        return groups
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var totalRepsAllTime: Int {
        allEntries
            .filter { !$0.exercise.isAutoTracked }
            .reduce(0) { $0 + $1.reps }
    }

    func totalReps(for exercise: ExerciseType) -> Int {
        allEntries
            .filter { $0.exercise == exercise }
            .reduce(0) { $0 + $1.reps }
    }
}
