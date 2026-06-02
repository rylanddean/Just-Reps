//
//  Just_RepsTests.swift
//  Just RepsTests
//
//  Created by Ryland Dean on 2026-05-09.
//

import Foundation
import Testing
@testable import Just_Reps

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    minute: Int = 0,
    calendar: Calendar = .current
) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

struct Just_RepsTests {

    @Test func logicalDayBoundsStartAtThreeAM() {
        let calendar = Calendar.current
        let bounds = StreakEngine.logicalDayBounds(for: .now)

        #expect(calendar.component(.hour, from: bounds.start) == 3)
        #expect(calendar.component(.minute, from: bounds.start) == 0)
        #expect(calendar.component(.hour, from: bounds.end) == 3)
        #expect(bounds.end > bounds.start)
    }

    @Test func streakEngineLongestIgnoresGap() {
        let calendar = Calendar.current
        let logicalDayDate = calendar.date(from: StreakEngine.logicalDay(for: .now))!
        // 5-day first streak, 3-day gap, 3-day second streak (most recent, just broken)
        let makeEntry: (Int) -> WorkoutEntry = { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: logicalDayDate)!
            return WorkoutEntry(exercise: .pushups, reps: 10,
                                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: day)!)
        }
        let entries = [
            makeEntry(-10), makeEntry(-9), makeEntry(-8), makeEntry(-7), makeEntry(-6), // 5-day streak
            // gap: -5, -4, -3 (no entries)
            makeEntry(-2), makeEntry(-1), makeEntry(0),  // 3-day streak (today included)
        ]

        let result = StreakEngine.calculate(entries: entries)

        #expect(result.longest == 5)
        #expect(result.current == 3)
    }

    @Test func streakEngineCountsContiguousDays() {
        let calendar = Calendar.current
        let logicalDayDate = calendar.date(from: StreakEngine.logicalDay(for: .now))!
        let day1 = calendar.date(byAdding: .day, value: -2, to: logicalDayDate)!
        let day2 = calendar.date(byAdding: .day, value: -1, to: logicalDayDate)!
        let day3 = logicalDayDate

        let entries = [
            WorkoutEntry(exercise: .pushups, reps: 10, timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: day1)!),
            WorkoutEntry(exercise: .pushups, reps: 10, timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: day2)!),
            WorkoutEntry(exercise: .pushups, reps: 10, timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: day3)!),
        ]

        let result = StreakEngine.calculate(entries: entries)

        #expect(result.current == 3)
        #expect(result.longest == 3)
    }

    @MainActor
    @Test func homeViewModelUsesLogicalDayRolloverForTodaysEntries() {
        let calendar = Calendar.current
        let logicalDayDate = calendar.date(from: StreakEngine.logicalDay(for: .now))!
        let beforeRollover = calendar.date(bySettingHour: 1, minute: 30, second: 0, of: logicalDayDate)!
        let afterRollover = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: logicalDayDate)!

        let viewModel = HomeViewModel()
        viewModel.refresh(with: [
            WorkoutEntry(exercise: .pushups, reps: 10, timestamp: beforeRollover),
            WorkoutEntry(exercise: .pushups, reps: 10, timestamp: afterRollover),
        ])

        #expect(viewModel.todaysEntries.count == 1)
        #expect(viewModel.todaysEntries.first?.timestamp == afterRollover)
    }

    @Test func weeklyAverageBucketsUseLivePeriodAndLogicalDays() {
        let calendar = Calendar.current
        let referenceDate = makeDate(year: 2026, month: 5, day: 11, hour: 9, calendar: calendar)
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!

        let entries = [
            WorkoutEntry(
                exercise: .pushups,
                reps: 14,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: previousWeekStart)!
            ),
            WorkoutEntry(
                exercise: .pushups,
                reps: 10,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: currentWeekStart)!
            ),
            WorkoutEntry(
                exercise: .pullups,
                reps: 6,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: currentWeekStart)!
            ),
        ]

        let buckets = StreakAnalytics.averageBuckets(
            entries: entries,
            period: .weekly,
            count: 2,
            referenceDate: currentWeekStart
        )

        #expect(buckets.count == 2)
        #expect(buckets[0].start == previousWeekStart)
        #expect(buckets[1].start == currentWeekStart)
        #expect(buckets[0].average(for: .pushups) == 2.0)
        #expect(buckets[1].average(for: .pushups) == 10.0)
        #expect(buckets[1].average(for: .pullups) == 6.0)
    }

    @Test func monthlyAverageBucketsUseLivePeriodAndLogicalDays() {
        let calendar = Calendar.current
        let referenceDate = makeDate(year: 2026, month: 5, day: 1, hour: 9, calendar: calendar)
        let currentMonthStart = calendar.dateInterval(of: .month, for: referenceDate)!.start
        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart)!

        let entries = [
            WorkoutEntry(
                exercise: .squats,
                reps: 31,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: previousMonthStart)!
            ),
            WorkoutEntry(
                exercise: .squats,
                reps: 16,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: currentMonthStart)!
            ),
        ]

        let buckets = StreakAnalytics.averageBuckets(
            entries: entries,
            period: .monthly,
            count: 2,
            referenceDate: currentMonthStart
        )

        #expect(buckets.count == 2)
        #expect(buckets[0].start == previousMonthStart)
        #expect(buckets[1].start == currentMonthStart)
        #expect(buckets[0].average(for: .squats) == 31.0 / 30.0)
        #expect(buckets[1].average(for: .squats) == 16.0)
    }

    @Test func chartPointsAreSortedByDateThenExercise() {
        let calendar = Calendar.current
        let referenceDate = makeDate(year: 2026, month: 5, day: 11, hour: 9, calendar: calendar)
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start
        let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!

        let entries = [
            WorkoutEntry(
                exercise: .pullups,
                reps: 5,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: currentWeekStart)!
            ),
            WorkoutEntry(
                exercise: .pushups,
                reps: 10,
                timestamp: calendar.date(bySettingHour: 4, minute: 0, second: 0, of: previousWeekStart)!
            ),
        ]

        let points = StreakAnalytics.chartPoints(
            entries: entries,
            period: .weekly,
            referenceDate: currentWeekStart
        )

        #expect(points.count == 4)
        #expect(points.map { $0.date } == [
            previousWeekStart,
            previousWeekStart,
            currentWeekStart,
            currentWeekStart
        ])
        #expect(points[0].exercise.displayName < points[1].exercise.displayName)
        #expect(points[2].exercise.displayName < points[3].exercise.displayName)
    }

}
