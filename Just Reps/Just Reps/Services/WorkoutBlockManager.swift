import BackgroundTasks
import EventKit
import Foundation

final class WorkoutBlockManager {

    static let shared = WorkoutBlockManager()
    private init() {}

    static let bgTaskID = "com.rylanddean.justreps.workoutblock"

    // MARK: - Background task

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            task.expirationHandler = { task.setTaskCompleted(success: false) }
            Task { @MainActor in
                WorkoutBlockManager.shared.scheduleBackgroundTask()
                // In the background we have no SwiftData context, so pass false and let
                // the repsEventExistsToday / alreadyScheduledToday guards prevent duplicates.
                WorkoutBlockManager.shared.scheduleBlockIfNeeded(hasLoggedToday: false)
                task.setTaskCompleted(success: true)
            }
        }
    }

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskID)
        request.earliestBeginDate = nextSixAM()
        try? BGTaskScheduler.shared.submit(request)
    }

    private func nextSixAM() -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: .now)
        comps.hour = 6; comps.minute = 0; comps.second = 0
        let todaySixAM = cal.date(from: comps)!
        return todaySixAM > .now
            ? todaySixAM
            : cal.date(byAdding: .day, value: 1, to: todaySixAM)!
    }

    private let store = EKEventStore()

    // MARK: - Authorization

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func requestAccess() async -> Bool {
        guard !isAuthorized else { return true }
        return (try? await store.requestFullAccessToEvents()) ?? false
    }

    var writableCalendars: [EKCalendar] {
        store.calendars(for: .event).filter { !$0.isImmutable }
    }

    var defaultCalendarID: String {
        store.defaultCalendarForNewEvents?.calendarIdentifier ?? ""
    }

    // MARK: - Scheduling

    func scheduleBlockIfNeeded(hasLoggedToday: Bool) {
        guard UserDefaults.standard.bool(forKey: "workoutBlockEnabled") else { return }
        guard !hasLoggedToday else { return }
        guard !alreadyScheduledToday() else { return }
        guard isAuthorized else { return }

        let calID = UserDefaults.standard.string(forKey: "workoutBlockCalendarID") ?? ""
        let calendar = (!calID.isEmpty ? store.calendar(withIdentifier: calID) : nil)
            ?? store.defaultCalendarForNewEvents
        guard let calendar else { return }
        guard !repsEventExistsToday(in: calendar) else { return }

        let ud = UserDefaults.standard
        let windows: [(enabled: Bool, sh: Int, sm: Int, eh: Int, em: Int)] = [
            (
                (ud.object(forKey: "workoutBlockAMEnabled") as? Bool) ?? true,
                (ud.object(forKey: "workoutBlockAMStartHour") as? Int) ?? 6,
                (ud.object(forKey: "workoutBlockAMStartMin")  as? Int) ?? 0,
                (ud.object(forKey: "workoutBlockAMEndHour")   as? Int) ?? 12,
                (ud.object(forKey: "workoutBlockAMEndMin")    as? Int) ?? 0
            ),
            (
                (ud.object(forKey: "workoutBlockPMEnabled") as? Bool) ?? false,
                (ud.object(forKey: "workoutBlockPMStartHour") as? Int) ?? 17,
                (ud.object(forKey: "workoutBlockPMStartMin")  as? Int) ?? 0,
                (ud.object(forKey: "workoutBlockPMEndHour")   as? Int) ?? 21,
                (ud.object(forKey: "workoutBlockPMEndMin")    as? Int) ?? 0
            ),
        ]

        for w in windows where w.enabled {
            if let slot = findFreeSlot(startHour: w.sh, startMinute: w.sm,
                                       endHour: w.eh, endMinute: w.em) {
                createEvent(at: slot, in: calendar)
                markScheduledToday()
                return
            }
        }
    }

    // MARK: - Private

    private func repsEventExistsToday(in calendar: EKCalendar) -> Bool {
        let today    = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let events   = store.events(
            matching: store.predicateForEvents(withStart: today, end: tomorrow, calendars: [calendar])
        )
        return events.contains { $0.title == "Reps" }
    }

    private func findFreeSlot(
        startHour: Int, startMinute: Int,
        endHour: Int,   endMinute: Int,
        duration: TimeInterval = 1800
    ) -> Date? {
        let today = Calendar.current.startOfDay(for: .now)
        guard
            let windowStart = Calendar.current.date(
                bySettingHour: startHour, minute: startMinute, second: 0, of: today),
            let windowEnd   = Calendar.current.date(
                bySettingHour: endHour,   minute: endMinute,   second: 0, of: today)
        else { return nil }

        let start = max(windowStart, .now)
        guard windowEnd.timeIntervalSince(start) >= duration else { return nil }

        let events = store.events(
            matching: store.predicateForEvents(withStart: start, end: windowEnd, calendars: nil)
        )
        .filter { !$0.isAllDay }
        .sorted { $0.startDate < $1.startDate }

        var cursor = start
        for event in events {
            if event.startDate.timeIntervalSince(cursor) >= duration { return cursor }
            if event.endDate > cursor { cursor = event.endDate }
        }
        return windowEnd.timeIntervalSince(cursor) >= duration ? cursor : nil
    }

    private func createEvent(at startDate: Date, in calendar: EKCalendar) {
        let event       = EKEvent(eventStore: store)
        event.title     = "Reps"
        event.startDate = startDate
        event.endDate   = startDate.addingTimeInterval(1800)
        event.calendar  = calendar
        try? store.save(event, span: .thisEvent, commit: true)
    }

    private func alreadyScheduledToday() -> Bool {
        guard let saved = UserDefaults.standard.object(forKey: "workoutBlockLastScheduled") as? Date
        else { return false }
        return Calendar.current.isDateInToday(saved)
    }

    private func markScheduledToday() {
        UserDefaults.standard.set(Date.now, forKey: "workoutBlockLastScheduled")
    }
}
