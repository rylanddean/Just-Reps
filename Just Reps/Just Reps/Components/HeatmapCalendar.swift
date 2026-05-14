import SwiftUI

struct HeatmapCalendar: View {
    let data: [DateComponents: Int]
    var weeks: Int = 20

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let gap: CGFloat = 3

    // MARK: - Date helpers

    /// The Sunday that opens the first displayed column.
    /// Always lands on an actual Sunday regardless of what day today is.
    private var startSunday: Date {
        let today = calendar.startOfDay(for: .now)
        // .weekday: 1 = Sunday, 7 = Saturday
        let daysSinceSunday = calendar.component(.weekday, from: today) - 1
        let thisSunday = calendar.date(byAdding: .day, value: -daysSinceSunday, to: today)!
        return calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisSunday)!
    }

    /// Exactly `weeks` columns, each a true Sun–Sat week.
    /// Dates beyond today (future cells in the current week) are nil so
    /// the column height stays fixed but the cell is invisible.
    private var weekColumns: [[Date?]] {
        let today = calendar.startOfDay(for: .now)
        return (0..<weeks).map { week in
            (0..<7).map { day -> Date? in
                let d = calendar.date(byAdding: .day, value: week * 7 + day, to: startSunday)!
                return d <= today ? d : nil
            }
        }
    }

    private var maxReps: Int { max(data.values.max() ?? 1, 1) }

    private func reps(for date: Date) -> Int {
        data[calendar.dateComponents([.year, .month, .day], from: date)] ?? 0
    }

    private func cellColor(for date: Date) -> Color {
        let r = reps(for: date)
        guard r > 0 else { return Color(UIColor.systemFill) }
        let intensity = max(0.2, Double(r) / Double(maxReps))
        return AppTheme.Colors.successGreen.opacity(intensity)
    }

    // MARK: - Month labels
    //
    // A label fires on the first column whose opening Sunday (first non-nil date)
    // falls in a different month than the previous labelled column.
    // This matches GitHub's contribution graph and guarantees the label sits
    // directly above the first full week of that month.

    private var monthLabels: [String?] {
        var result: [String?] = Array(repeating: nil, count: weekColumns.count)
        var lastMonth: Int? = nil
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"

        for (col, column) in weekColumns.enumerated() {
            // Use the first real (non-nil) date in the column — the opening Sunday
            guard let firstDate = column.compactMap({ $0 }).first else { continue }
            let month = calendar.component(.month, from: firstDate)
            if month != lastMonth {
                result[col] = fmt.string(from: firstDate)
                lastMonth = month
            }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: gap) {
            dayOfWeekColumn
            gridColumns
        }
    }

    // MARK: - Day-of-week labels

    private var dayOfWeekColumn: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 10, height: cellSize)
            }
        }
    }

    // MARK: - Week columns

    private var gridColumns: some View {
        HStack(alignment: .top, spacing: gap) {
            ForEach(weekColumns.indices, id: \.self) { col in
                VStack(alignment: .leading, spacing: gap) {
                    // 7 rows per column; nil = future date = invisible placeholder
                    ForEach(0..<7, id: \.self) { row in
                        if let date = weekColumns[col][row] {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cellColor(for: date))
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}
