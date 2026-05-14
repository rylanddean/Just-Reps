import SwiftUI

struct WatchMilestonesView: View {
    var vm: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                milestoneSection(
                    title: "REP STREAK",
                    streak: vm.loggedStreak,
                    color: WatchTheme.successGreen
                )
                milestoneSection(
                    title: "GOAL STREAK",
                    streak: vm.goalsStreak,
                    color: WatchTheme.coolBlue
                )
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func milestoneSection(title: String, streak: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            ForEach(WatchViewModel.milestoneThresholds, id: \.self) { days in
                HStack(spacing: 8) {
                    Image(systemName: streak >= days ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(streak >= days ? color : Color.secondary.opacity(0.3))
                    Text("\(days) days")
                        .font(.caption)
                        .foregroundStyle(streak >= days ? .primary : Color.secondary.opacity(0.5))
                    Spacer()
                }
            }

            if let next = vm.nextMilestone(for: streak) {
                let remaining = next - streak
                Text("\(remaining) day\(remaining == 1 ? "" : "s") to \(next)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else {
                Text("All milestones reached.")
                    .font(.caption2)
                    .foregroundStyle(color)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
