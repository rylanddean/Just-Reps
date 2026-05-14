import SwiftUI

struct GoalSuggestionCard: View {
    let recommendation: GoalRecommendation
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(recommendation.exercise.emoji)
                        .font(.title3)
                    Text(recommendation.exercise.displayName)
                        .font(AppTheme.Font.headline())
                }
                Spacer()
                Image(systemName: recommendation.direction == .increase ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(recommendation.direction == .increase
                                     ? AppTheme.Colors.successGreen
                                     : AppTheme.Colors.streakDanger)
            }

            Text(recommendation.headline)
                .font(AppTheme.Font.body())
                .foregroundStyle(.secondary)

            HStack(spacing: AppTheme.Spacing.md) {
                goalStat(value: recommendation.currentGoal, label: "NOW")
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                goalStat(value: recommendation.suggestedGoal, label: "SUGGESTED")
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onApply()
                } label: {
                    Text("Apply")
                        .font(AppTheme.Font.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.label))
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    onDismiss()
                } label: {
                    Text("Keep as is")
                        .font(AppTheme.Font.body())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func goalStat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            Text(label)
                .font(AppTheme.Font.caption())
                .kerning(0.8)
                .foregroundStyle(.secondary)
        }
    }
}
