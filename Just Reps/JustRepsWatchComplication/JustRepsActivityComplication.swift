import WidgetKit
import SwiftUI

private let successGreen = Color(red: 95/255, green: 211/255, blue: 141/255)

// MARK: - Entry

struct ActivityComplicationEntry: TimelineEntry {
    let date: Date
    /// 30 elements, index 0 = oldest (29 days ago), index 29 = today
    let repsLast30Days: [Int]
}

// MARK: - Provider

struct ActivityComplicationProvider: TimelineProvider {
    private static let appGroupID = "group.com.rylanddean.justreps"

    func placeholder(in context: Context) -> ActivityComplicationEntry {
        ActivityComplicationEntry(date: .now, repsLast30Days: previewReps)
    }

    func getSnapshot(in context: Context, completion: @escaping (ActivityComplicationEntry) -> Void) {
        completion(ActivityComplicationEntry(date: .now, repsLast30Days: loadReps()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityComplicationEntry>) -> Void) {
        let entry = ActivityComplicationEntry(date: .now, repsLast30Days: loadReps())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadReps() -> [Int] {
        guard let data = UserDefaults(suiteName: Self.appGroupID)?
                  .data(forKey: "last30DaysReps"),
              let decoded = try? JSONDecoder().decode([Int].self, from: data),
              decoded.count == 30
        else { return Array(repeating: 0, count: 30) }
        return decoded
    }
}

private let previewReps: [Int] = [
     0, 25, 30,  0, 50, 25, 30,  0, 45, 25,
    20,  0, 30, 25, 35,  0, 50, 25, 30,  0,
    20, 25, 30, 35,  0, 50, 25, 30, 25, 40
]

// MARK: - Grid (10 columns × 3 rows = 30 cells, fills accessoryRectangular)

private struct ActivityGrid: View {
    let reps: [Int]

    private let columns = 10
    private let rows    = 3
    private let cell: CGFloat = 13
    private let gap: CGFloat  = 2

    private var peak: Int { max(reps.max() ?? 1, 1) }

    private func fill(for count: Int) -> Color {
        count == 0
            ? Color.secondary.opacity(0.2)
            : successGreen.opacity(max(0.35, Double(count) / Double(peak)))
    }

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<columns, id: \.self) { col in
                        let i = row * columns + col
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fill(for: i < reps.count ? reps[i] : 0))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }
}

// MARK: - Complication view

struct JustRepsActivityComplicationView: View {
    let entry: ActivityComplicationEntry

    var body: some View {
        ActivityGrid(reps: entry.repsLast30Days)
    }
}

// MARK: - Widget

struct JustRepsActivityWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.rylanddean.justreps.activity",
            provider: ActivityComplicationProvider()
        ) { entry in
            JustRepsActivityComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Activity Chart")
        .description("30 days of rep activity.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    JustRepsActivityWidget()
} timeline: {
    ActivityComplicationEntry(date: .now, repsLast30Days: previewReps)
}
