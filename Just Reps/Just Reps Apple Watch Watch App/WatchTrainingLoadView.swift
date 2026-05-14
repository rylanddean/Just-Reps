import SwiftUI

struct WatchTrainingLoadView: View {
    var vm: WatchViewModel

    var body: some View {
        if !vm.hasTrainingLoadData {
            VStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Open iPhone app to sync.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Text("Training Load")
                            .font(.headline)
                        Spacer()
                        trendBadge
                    }

                    HStack(spacing: 8) {
                        statCell(value: vm.trainingLoadTodayMins, label: "TODAY")
                        statCell(value: vm.trainingLoadWeeklyMins, label: "7 DAYS")
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private var trendBadge: some View {
        let style = trendStyle(for: vm.trainingLoadTrend)
        Image(systemName: style.icon)
            .font(.caption.bold())
            .foregroundStyle(style.color)
    }

    private func trendStyle(for trend: String) -> (icon: String, color: Color) {
        switch trend {
        case "up":   return ("arrow.up.right", WatchTheme.streakDanger)
        case "down": return ("arrow.down.right", WatchTheme.coolBlue)
        default:     return ("minus", .secondary)
        }
    }

    private func statCell(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            Text("\(label) MIN")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
