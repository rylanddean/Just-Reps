import WidgetKit
import SwiftUI

// MARK: - Colors (mirrored from WatchTheme — no cross-target dependency)

private let successGreen = Color(red: 95/255, green: 211/255, blue: 141/255)

// MARK: - Timeline

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let activityLast7Days: [Bool]
    let isAtRisk: Bool
}

struct JustRepsComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: .now, streak: 7,
                          activityLast7Days: [true, false, true, true, false, true, true],
                          isAtRisk: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let streak = currentStreak()
        completion(ComplicationEntry(date: .now, streak: streak,
                                     activityLast7Days: currentActivity(),
                                     isAtRisk: computeIsAtRisk(streak: streak)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let streak = currentStreak()
        let entry = ComplicationEntry(date: .now, streak: streak,
                                      activityLast7Days: currentActivity(),
                                      isAtRisk: computeIsAtRisk(streak: streak))
        // Refresh every hour; Watch app also calls reloadAllTimelines() after each log
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentStreak() -> Int {
        UserDefaults(suiteName: "group.com.rylanddean.justreps")?
            .integer(forKey: "currentRepStreak") ?? 0
    }

    private func currentActivity() -> [Bool] {
        guard let data = UserDefaults(suiteName: "group.com.rylanddean.justreps")?
            .data(forKey: "last7DaysActivity"),
              let decoded = try? JSONDecoder().decode([Bool].self, from: data),
              decoded.count == 7
        else {
            return Array(repeating: false, count: 7)
        }
        return decoded
    }

    private func computeIsAtRisk(streak: Int) -> Bool {
        guard streak > 0 else { return false }
        let hour = Calendar.current.component(.hour, from: .now)
        guard hour >= 20 else { return false }
        return !(currentActivity().last ?? false)
    }
}

// MARK: - Views

struct JustRepsComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            circularView
        }
    }

    private var streakColor: Color {
        entry.isAtRisk ? .red : (entry.streak > 0 ? successGreen : .secondary)
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                if entry.isAtRisk {
                    Text("⚠")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.red)
                    Text("NOW")
                        .font(.system(size: 7, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.red)
                } else {
                    Text("\(entry.streak)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(streakColor)
                    Text("DAYS")
                        .font(.system(size: 7, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var cornerView: some View {
        Group {
            if entry.isAtRisk {
                Text("⚠")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.red)
                    .widgetLabel("LOG NOW")
            } else {
                Text("\(entry.streak)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(streakColor)
                    .widgetLabel("REP STREAK")
            }
        }
    }

    private var inlineView: some View {
        if entry.isAtRisk {
            return Text("⚠ Streak at risk")
        } else {
            return Text(entry.streak > 0 ? "🔥 \(entry.streak)" : "Log reps")
        }
    }

    private var rectangularView: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.isAtRisk ? "STREAK AT RISK" : "REP STREAK")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(entry.isAtRisk ? .red : .secondary)
                if entry.isAtRisk {
                    Text("⚠")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.red)
                    Text("Log reps tonight.")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.8))
                } else {
                    Text("\(entry.streak)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(streakColor)
                    Text(entry.streak == 1 ? "day" : "days")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !entry.isAtRisk { activityBars }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activityBars: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(entry.activityLast7Days.indices, id: \.self) { i in
                let active = entry.activityLast7Days[i]
                RoundedRectangle(cornerRadius: 2)
                    .fill(active ? successGreen : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: active ? 22 : 10)
            }
        }
        .padding(.bottom, 2)
    }
}

// MARK: - Widget

struct JustRepsStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.rylanddean.justreps.streak",
            provider: JustRepsComplicationProvider()
        ) { entry in
            JustRepsComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rep Streak")
        .description("Your current Just Reps streak.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .accessoryCircular) {
    JustRepsStreakWidget()
} timeline: {
    ComplicationEntry(date: .now, streak: 12,
                      activityLast7Days: [true, false, true, true, true, false, true],
                      isAtRisk: false)
}

#Preview(as: .accessoryRectangular) {
    JustRepsStreakWidget()
} timeline: {
    ComplicationEntry(date: .now, streak: 12,
                      activityLast7Days: [true, false, true, true, true, false, true],
                      isAtRisk: false)
}

#Preview("At Risk", as: .accessoryRectangular) {
    JustRepsStreakWidget()
} timeline: {
    ComplicationEntry(date: .now, streak: 12,
                      activityLast7Days: [true, false, true, true, true, false, false],
                      isAtRisk: true)
}
