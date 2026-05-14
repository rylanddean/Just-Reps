import SwiftUI

struct StreakCounter: View {
    let streak: Int
    let completedToday: Bool
    var atRisk: Bool = false

    private var accentColor: Color {
        if streak == 0 || atRisk { return AppTheme.Colors.streakDanger }
        return completedToday ? AppTheme.Colors.successGreen : Color(UIColor.label)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(streak)")
                .font(AppTheme.Font.display())
                .foregroundStyle(accentColor)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: streak)

            Text("DAY STREAK")
                .font(AppTheme.Font.caption())
                .fontWeight(.semibold)
                .kerning(2)
                .foregroundStyle(.secondary)
        }
    }
}

// Compact variant used in the tab bar or widgets
struct StreakCounterCompact: View {
    let streak: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? AppTheme.Colors.successGreen : AppTheme.Colors.streakDanger)
            Text("\(streak)")
                .font(AppTheme.Font.headline())
                .foregroundStyle(Color(UIColor.label))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: streak)
        }
    }
}
