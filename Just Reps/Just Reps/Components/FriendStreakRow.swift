import SwiftUI

struct FriendStreakRow: View {
    let entry: GameCenterManager.FriendEntry

    var body: some View {
        HStack {
            Text(entry.displayName)
                .font(AppTheme.Font.headline())
                .foregroundStyle(
                    entry.isLocalPlayer
                        ? AppTheme.Colors.successGreen
                        : AppTheme.Colors.primaryText
                )

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(entry.streak)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        entry.isLocalPlayer
                            ? AppTheme.Colors.successGreen
                            : AppTheme.Colors.primaryText
                    )
                    .contentTransition(.numericText())
                Text(entry.streak == 1 ? "day" : "days")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(
            entry.isLocalPlayer
                ? AppTheme.Colors.successGreen.opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }
}
