import SwiftUI

struct WatchStreakView: View {
    var vm: WatchViewModel

    var body: some View {
        VStack(spacing: 0) {
            streakCell(
                value: vm.loggedStreak,
                label: "REP STREAK",
                color: WatchTheme.successGreen
            )
            Rectangle()
                .fill(.separator)
                .frame(height: 0.5)
                .padding(.horizontal, 20)
            streakCell(
                value: vm.goalsStreak,
                label: "GOAL STREAK",
                color: WatchTheme.coolBlue
            )
        }
    }

    @ViewBuilder
    private func streakCell(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(value > 0 ? color : Color.secondary)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
    }
}
