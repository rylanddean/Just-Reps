import SwiftUI

struct StreakExplainerSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Two streaks.")
                .font(AppTheme.Font.title())
                .fontWeight(.bold)
                .padding(.top, AppTheme.Spacing.lg)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                streakRow(
                    label: "REP STREAK",
                    color: AppTheme.Colors.successGreen,
                    description: "Any reps logged today keep this alive. Even 5 counts."
                )
                streakRow(
                    label: "GOAL STREAK",
                    color: AppTheme.Colors.coolBlue,
                    description: "All daily goals met today. Harder to hold. Worth building."
                )
            }

            Spacer()

            Button(action: onDismiss) {
                Text("Got it")
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(UIColor.label))
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func streakRow(label: String, color: Color, description: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(label)
                    .font(AppTheme.Font.caption())
                    .kerning(1)
                    .foregroundStyle(color)
                Text(description)
                    .font(AppTheme.Font.body())
                    .foregroundStyle(Color(UIColor.label))
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}
