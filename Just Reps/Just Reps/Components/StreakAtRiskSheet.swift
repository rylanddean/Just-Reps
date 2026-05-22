import SwiftUI
import SwiftData

struct StreakAtRiskSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            exerciseList
            actions
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(UIColor.systemBackground))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("Streak at Risk")
                .font(AppTheme.Font.title())
            Text("Log a few reps before midnight to keep your \(viewModel.loggedStreak)-day streak alive.")
                .font(AppTheme.Font.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.lg)
    }

    // MARK: - Remaining exercises

    private var exerciseList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(viewModel.unmetExercises, id: \.exercise) { item in
                HStack {
                    Text(item.exercise.displayName)
                        .font(AppTheme.Font.body())
                    Spacer()
                    Text("\(item.remaining) left")
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.streakDanger)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                dismiss()
            } label: {
                Text("Log Reps")
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.successGreen)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            }
            .buttonStyle(.plain)

            if viewModel.freezeTokens > 0 {
                Button {
                    viewModel.freezeToday(context: modelContext)
                    dismiss()
                } label: {
                    Text("Freeze Streak (\(viewModel.freezeTokens) left)")
                        .font(AppTheme.Font.body())
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.Colors.coolBlue.opacity(0.15))
                        .foregroundStyle(AppTheme.Colors.coolBlue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                }
                .buttonStyle(.plain)
            }

            Button("Dismiss") { dismiss() }
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
                .padding(.bottom, AppTheme.Spacing.sm)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}
