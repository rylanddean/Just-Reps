import SwiftUI

struct WatchActivityView: View {
    var vm: WatchViewModel

    private var data: [(date: Date, reps: Int, isFreeze: Bool, isRest: Bool)] { vm.last7DaysActivity }
    private var maxReps: Int { max(data.map(\.reps).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(data.indices, id: \.self) { i in
                    let item = data[i]
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(for: item))
                            .frame(height: barHeight(for: item.reps, isFreeze: item.isFreeze, isRest: item.isRest))
                        Text(dayLetter(from: item.date))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 76)
            .padding(.horizontal, 4)

            if data.allSatisfy({ $0.reps == 0 && !$0.isFreeze && !$0.isRest }) {
                Text("Come back after a week.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            Text("Just Reps \(appVersion)")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 4)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func barColor(for item: (date: Date, reps: Int, isFreeze: Bool, isRest: Bool)) -> Color {
        if item.isFreeze { return Color(red: 107/255, green: 168/255, blue: 255/255) }
        if item.isRest { return Color.white.opacity(0.25) }
        return item.reps > 0 ? WatchTheme.successGreen : Color.white.opacity(0.12)
    }

    private func barHeight(for reps: Int, isFreeze: Bool, isRest: Bool) -> CGFloat {
        if isFreeze || isRest { return 6 }
        guard reps > 0 else { return 4 }
        return max(CGFloat(reps) / CGFloat(maxReps) * 58, 6)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f
    }()

    private func dayLetter(from date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }
}
