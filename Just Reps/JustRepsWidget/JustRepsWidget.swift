import WidgetKit
import SwiftUI

// MARK: - Colors (mirrored from AppTheme — no cross-target dependency)

private let successGreen = Color(red: 95/255, green: 211/255, blue: 141/255)
private let streakDanger = Color(red: 255/255, green: 107/255, blue: 107/255)
private let coolBlue     = Color(red: 107/255, green: 168/255, blue: 255/255)

// MARK: - App Group

private let appGroupID = "group.com.rylanddean.justreps"

// MARK: - Entry

struct JustRepsWidgetEntry: TimelineEntry {
    let date: Date
    let repStreak: Int
    let goalStreak: Int
    let isRepAtRisk: Bool
    let isGoalAtRisk: Bool
    // "YYYY-MM-DD" → has activity
    let heatmap: [String: Bool]
    let isPlaceholder: Bool

    static let placeholder = JustRepsWidgetEntry(
        date: .now,
        repStreak: 0,
        goalStreak: 0,
        isRepAtRisk: false,
        isGoalAtRisk: false,
        heatmap: [:],
        isPlaceholder: true
    )
}

// MARK: - Provider

struct JustRepsWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> JustRepsWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (JustRepsWidgetEntry) -> Void) {
        completion(context.isPreview ? previewEntry() : currentEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JustRepsWidgetEntry>) -> Void) {
        var entries: [JustRepsWidgetEntry] = []
        let now = Date.now
        entries.append(currentEntry(for: now))

        // If it's before 8 PM, emit a second entry at 8 PM to flip the at-risk color
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        if hour < 20, let atRiskTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) {
            entries.append(currentEntry(for: atRiskTime))
        }

        // Refresh at the next 3 AM logical day rollover
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let rollover = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: tomorrow)!

        completion(Timeline(entries: entries, policy: .after(rollover)))
    }

    // MARK: - Helpers

    private func currentEntry(for date: Date) -> JustRepsWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let repStreak  = defaults?.integer(forKey: "currentRepStreak") ?? 0
        let goalStreak = defaults?.integer(forKey: "currentGoalsStreak") ?? 0
        let heatmap    = loadHeatmap(from: defaults)

        let hour       = Calendar.current.component(.hour, from: date)
        let isAtRisk   = hour >= 20
        let loggedToday = heatmap[dayKey(from: date)] == true

        return JustRepsWidgetEntry(
            date: date,
            repStreak: repStreak,
            goalStreak: goalStreak,
            isRepAtRisk: isAtRisk && repStreak > 0 && !loggedToday,
            isGoalAtRisk: isAtRisk && goalStreak > 0 && !loggedToday,
            heatmap: heatmap,
            isPlaceholder: false
        )
    }

    private func loadHeatmap(from defaults: UserDefaults?) -> [String: Bool] {
        guard
            let data = defaults?.data(forKey: "widgetHeatmap"),
            let decoded = try? JSONDecoder().decode([String: Bool].self, from: data)
        else { return [:] }
        return decoded
    }

    private func dayKey(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    private func previewEntry() -> JustRepsWidgetEntry {
        var heatmap: [String: Bool] = [:]
        let calendar = Calendar.current
        for i in 0..<56 {
            guard let day = calendar.date(byAdding: .day, value: -i, to: .now) else { continue }
            if i % 3 != 2 { heatmap[dayKey(from: day)] = true }
        }
        return JustRepsWidgetEntry(
            date: .now,
            repStreak: 14,
            goalStreak: 7,
            isRepAtRisk: false,
            isGoalAtRisk: false,
            heatmap: heatmap,
            isPlaceholder: false
        )
    }
}

// MARK: - Root view

struct JustRepsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: JustRepsWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryInline:
            inlineView
        default:
            smallView
        }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("REP STREAK")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            if entry.isPlaceholder {
                Text("—")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(entry.repStreak)")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(streakColor(streak: entry.repStreak, atRisk: entry.isRepAtRisk))
                    .contentTransition(.numericText())
            }

            Text(entry.repStreak == 1 ? "day" : "days")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Text("Just do the reps.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .widgetURL(URL(string: "justreps://today"))
    }

    // MARK: - Medium

    private var mediumView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                streakCell(
                    value: entry.isPlaceholder ? nil : entry.repStreak,
                    label: "REP STREAK",
                    atRisk: entry.isRepAtRisk,
                    activeColor: successGreen
                )
                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(width: 0.5)
                    .padding(.vertical, 8)
                streakCell(
                    value: entry.isPlaceholder ? nil : entry.goalStreak,
                    label: "GOAL STREAK",
                    atRisk: entry.isGoalAtRisk,
                    activeColor: coolBlue
                )
            }

            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 0.5)

            heatmapGrid
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "justreps://today"))
    }

    private func streakCell(value: Int?, label: String, atRisk: Bool, activeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
            Group {
                if let v = value {
                    Text("\(v)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(streakColor(streak: v, atRisk: atRisk, activeColor: activeColor))
                        .contentTransition(.numericText())
                } else {
                    Text("—")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Text(value == 1 ? "day" : "days")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Heatmap (8 weeks × 7 days)

    private var heatmapGrid: some View {
        let columns = weekColumns()
        return HStack(alignment: .top, spacing: 3) {
            ForEach(columns.indices, id: \.self) { wi in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { di in
                        dot(for: columns[wi][di])
                    }
                }
            }
        }
    }

    private func dot(for date: Date?) -> some View {
        let key = date.map { dayKey(from: $0) } ?? ""
        let isFuture = date.map { $0 > .now } ?? true
        let isActive = !isFuture && entry.heatmap[key] == true

        return RoundedRectangle(cornerRadius: 2)
            .fill(isFuture ? Color.clear : (isActive ? successGreen : Color.secondary.opacity(0.15)))
            .frame(width: 8, height: 8)
    }

    // 8 week columns, each column is 7 dates (Sun–Sat), nil for future
    private func weekColumns() -> [[Date?]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today) // 1 = Sun
        guard let thisSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }

        var columns: [[Date?]] = []
        for w in stride(from: 7, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -w, to: thisSunday) else { continue }
            var days: [Date?] = []
            for d in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: d, to: weekStart) else { continue }
                days.append(day > .now ? nil : day)
            }
            columns.append(days)
        }
        return columns
    }

    // MARK: - Lock screen inline

    private var inlineView: some View {
        let label: String
        if entry.isPlaceholder {
            label = "— day streak"
        } else {
            label = entry.repStreak == 1 ? "1 day streak" : "\(entry.repStreak) day streak"
        }
        return Text(label)
    }

    // MARK: - Helpers

    private func streakColor(streak: Int, atRisk: Bool, activeColor: Color = successGreen) -> Color {
        if streak == 0 { return .secondary }
        if atRisk { return streakDanger }
        return activeColor
    }

    private func dayKey(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

// MARK: - Widget

struct JustRepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.rylanddean.justreps.homewidget",
            provider: JustRepsWidgetProvider()
        ) { entry in
            JustRepsWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Just Reps")
        .description("Your streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline])
    }
}

// MARK: - Heatmap-only widget

struct JustRepsHeatmapView: View {
    @Environment(\.widgetFamily) var family
    let entry: JustRepsWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVITY")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            heatmapGrid
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .widgetURL(URL(string: "justreps://today"))
    }

    private var weekCount: Int { family == .systemMedium ? 13 : 8 }

    private var heatmapGrid: some View {
        let columns = weekColumns(count: weekCount)
        return HStack(alignment: .top, spacing: 3) {
            ForEach(columns.indices, id: \.self) { wi in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { di in
                        dot(for: columns[wi][di])
                    }
                }
            }
        }
    }

    private func dot(for date: Date?) -> some View {
        let key = date.map { dayKey(from: $0) } ?? ""
        let isFuture = date.map { $0 > .now } ?? true
        let isActive = !isFuture && entry.heatmap[key] == true

        return RoundedRectangle(cornerRadius: 2)
            .fill(isFuture ? Color.clear : (isActive ? successGreen : Color.secondary.opacity(0.15)))
            .frame(width: 8, height: 8)
    }

    private func weekColumns(count: Int) -> [[Date?]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        guard let thisSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }

        var columns: [[Date?]] = []
        for w in stride(from: count - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -w, to: thisSunday) else { continue }
            var days: [Date?] = []
            for d in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: d, to: weekStart) else { continue }
                days.append(day > .now ? nil : day)
            }
            columns.append(days)
        }
        return columns
    }

    private func dayKey(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = c.year, let m = c.month, let d = c.day else { return "" }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

struct JustRepsHeatmapWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.rylanddean.justreps.heatmap",
            provider: JustRepsWidgetProvider()
        ) { entry in
            JustRepsHeatmapView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Just Reps — Activity")
        .description("Your activity over the past weeks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    JustRepsWidget()
} timeline: {
    JustRepsWidgetEntry(
        date: .now, repStreak: 14, goalStreak: 7,
        isRepAtRisk: false, isGoalAtRisk: false,
        heatmap: [:], isPlaceholder: false
    )
}

#Preview("Medium", as: .systemMedium) {
    JustRepsWidget()
} timeline: {
    JustRepsWidgetEntry(
        date: .now, repStreak: 14, goalStreak: 7,
        isRepAtRisk: false, isGoalAtRisk: false,
        heatmap: [:], isPlaceholder: false
    )
}

#Preview("At-risk", as: .systemSmall) {
    JustRepsWidget()
} timeline: {
    JustRepsWidgetEntry(
        date: .now, repStreak: 14, goalStreak: 7,
        isRepAtRisk: true, isGoalAtRisk: true,
        heatmap: [:], isPlaceholder: false
    )
}

#Preview("Heatmap Small", as: .systemSmall) {
    JustRepsHeatmapWidget()
} timeline: {
    JustRepsWidgetEntry(
        date: .now, repStreak: 14, goalStreak: 7,
        isRepAtRisk: false, isGoalAtRisk: false,
        heatmap: [:], isPlaceholder: false
    )
}

#Preview("Heatmap Medium", as: .systemMedium) {
    JustRepsHeatmapWidget()
} timeline: {
    JustRepsWidgetEntry(
        date: .now, repStreak: 14, goalStreak: 7,
        isRepAtRisk: false, isGoalAtRisk: false,
        heatmap: [:], isPlaceholder: false
    )
}
