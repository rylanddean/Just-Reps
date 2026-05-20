import Combine
import Foundation
import SwiftData

// Pure streak calculation — no SwiftUI dependencies so it's easily unit-tested.
struct StreakEngine {

    // 3AM grace window: days roll over at 3AM instead of midnight so late-night
    // athletes don't lose a streak if they log at 12:30AM.
    static let rolloverHour = 3

    // MARK: - Result type

    struct Result {
        let current: Int
        let longest: Int
        let completedDates: Set<DateComponents> // year+month+day keys
    }

    // MARK: - Entry-based calculation (logged streak)

    static func calculate(entries: [WorkoutEntry]) -> Result {
        guard !entries.isEmpty else {
            return Result(current: 0, longest: 0, completedDates: [])
        }
        let completedDays = Set(entries.map { logicalDay(for: $0.timestamp) })
        let (current, longest) = calculateStreak(from: completedDays)
        return Result(current: current, longest: longest, completedDates: completedDays)
    }

    /// MVR-aware streak: mirrors the iOS StreakEngine overload so Watch and phone agree.
    static func calculate(
        entries: [WorkoutEntry],
        activeExercises: [ExerciseType],
        goals: [ExerciseType: Int],
        minimumViableReps: [ExerciseType: Int],
        effectiveFrom: Date? = nil
    ) -> Result {
        guard !entries.isEmpty else {
            return Result(current: 0, longest: 0, completedDates: [])
        }
        let effectiveLogicalDay = effectiveFrom.map { logicalDay(for: $0) }
        var dayMap: [DateComponents: [WorkoutEntry]] = [:]
        for entry in entries {
            let day = logicalDay(for: entry.timestamp)
            dayMap[day, default: []].append(entry)
        }
        var qualifiedDays = Set<DateComponents>()
        for (day, dayEntries) in dayMap {
            if dayEntries.contains(where: { $0.kind == .rest || $0.kind == .freeze }) {
                qualifiedDays.insert(day)
                continue
            }
            guard dayEntries.contains(where: { $0.kind == .workout }) else { continue }
            if let effectiveLD = effectiveLogicalDay,
               let dayDate = Calendar.current.date(from: day),
               let effectiveDate = Calendar.current.date(from: effectiveLD),
               dayDate < effectiveDate {
                qualifiedDays.insert(day)
                continue
            }
            let allSatisfied = activeExercises.allSatisfy { exercise in
                let mvr = minimumViableReps[exercise] ?? 0
                guard mvr > 0 else { return true }
                let reps = dayEntries
                    .filter { $0.kind == .workout && $0.exercise == exercise }
                    .reduce(0) { $0 + $1.reps }
                return reps >= mvr || reps >= (goals[exercise] ?? Int.max)
            }
            if allSatisfied { qualifiedDays.insert(day) }
        }
        let (current, longest) = calculateStreak(from: qualifiedDays)
        return Result(current: current, longest: longest, completedDates: qualifiedDays)
    }

    // MARK: - Generic streak from any set of completed days

    /// Compute current + longest streak from a pre-built set of logical day keys.
    /// Used for both "logged" and "goals met" streaks.
    static func calculateStreak(from completedDays: Set<DateComponents>) -> (current: Int, longest: Int) {
        guard !completedDays.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let sorted = completedDays.sorted {
            calendar.date(from: $0)! < calendar.date(from: $1)!
        }

        var longest = 1
        var run = 1
        for i in 1..<sorted.count {
            let prev = calendar.date(from: sorted[i - 1])!
            let curr = calendar.date(from: sorted[i])!
            if calendar.dateComponents([.day], from: prev, to: curr).day == 1 {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }
        longest = max(longest, run)

        // Current streak: walk backwards through logical days.
        var current = 0
        var checkDay = logicalDay(for: .now)
        while completedDays.contains(checkDay) {
            current += 1
            checkDay = previousLogicalDay(before: checkDay)
        }

        // If today isn't done yet, preserve yesterday's streak in the display
        if current == 0 {
            var ydKey = previousLogicalDay(before: logicalDay(for: .now))
            while completedDays.contains(ydKey) {
                current += 1
                ydKey = previousLogicalDay(before: ydKey)
            }
        }

        return (current, longest)
    }

    // MARK: - Today's status

    static func completedToday(entries: [WorkoutEntry]) -> Bool {
        let today = logicalDay(for: .now)
        return entries.contains { logicalDay(for: $0.timestamp) == today }
    }

    // MARK: - Monthly consistency

    static func monthlyConsistency(entries: [WorkoutEntry], month: Date = .now) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard
            let firstDay = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: firstDay)
        else { return 0 }

        let daysInMonth = range.count
        let result = calculate(entries: entries)
        let matchingDays = result.completedDates.filter {
            $0.year == components.year && $0.month == components.month
        }.count

        return Double(matchingDays) / Double(daysInMonth)
    }

    // MARK: - Heatmap data

    static func heatmapData(entries: [WorkoutEntry], days: Int = 365) -> [DateComponents: Int] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        var map: [DateComponents: Int] = [:]
        for entry in entries where entry.timestamp >= cutoff {
            let key = logicalDay(for: entry.timestamp)
            map[key, default: 0] += entry.reps
        }
        return map
    }

    // MARK: - Logical day (internal so ViewModels can use it for goals streak)

    static func logicalDay(for date: Date) -> DateComponents {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var components = cal.dateComponents([.year, .month, .day, .hour], from: date)
        if let hour = components.hour, hour < rolloverHour {
            let shifted = cal.date(byAdding: .day, value: -1, to: date)!
            components = cal.dateComponents([.year, .month, .day], from: shifted)
        } else {
            components = cal.dateComponents([.year, .month, .day], from: date)
        }
        return components
    }

    static func logicalDayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let day = calendar.date(from: logicalDay(for: date))!
        let start = calendar.date(bySettingHour: rolloverHour, minute: 0, second: 0, of: day)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    static func previousLogicalDay(before day: DateComponents) -> DateComponents {
        let calendar = Calendar.current
        let dayStart = calendar.date(from: day)!
        let anchor = calendar.date(bySettingHour: rolloverHour, minute: 0, second: 0, of: dayStart)!
        let previousAnchor = calendar.date(byAdding: .day, value: -1, to: anchor)!
        return logicalDay(for: previousAnchor)
    }
}
