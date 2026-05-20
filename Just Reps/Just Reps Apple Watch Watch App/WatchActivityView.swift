import SwiftUI

struct WatchActivityView: View {
    var vm: WatchViewModel

    private var data: [(date: Date, reps: Int)] { vm.last7DaysActivity }
    private var maxReps: Int { max(data.map(\.reps).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(data, id: \.date) { item in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.reps > 0 ? WatchTheme.successGreen : Color.white.opacity(0.12))
                            .frame(height: barHeight(for: item.reps))
                        Text(dayLetter(from: item.date))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 76)
            .padding(.horizontal, 4)

            if data.allSatisfy({ $0.reps == 0 }) {
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

    private func barHeight(for reps: Int) -> CGFloat {
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
