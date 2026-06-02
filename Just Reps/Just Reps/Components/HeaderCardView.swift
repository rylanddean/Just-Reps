import SwiftUI

struct HeaderCardView: View {
    var viewModel: HomeViewModel
    var onFreezeRequested: (() -> Void)? = nil

    @AppStorage("hasSeenStreakExplainer") private var hasSeenStreakExplainer = false
    @State private var showExplainer = false

    var body: some View {
        streakRow
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showExplainer) {
                StreakExplainerSheet {
                    hasSeenStreakExplainer = true
                    showExplainer = false
                }
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
            }
    }

    // MARK: - Streak cells

    private var streakRow: some View {
        HStack(spacing: 0) {
            repStreakCell
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(width: 0.5, height: 44)
            streakCell(
                value: viewModel.goalsStreak,
                label: "GOAL STREAK",
                isAtRisk: viewModel.goalsStreakAtRisk,
                activeColor: AppTheme.Colors.coolBlue
            )
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .overlay(alignment: .topTrailing) {
            if !hasSeenStreakExplainer {
                Button { showExplainer = true } label: {
                    Text("?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.coolBlue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.Colors.coolBlue.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding([.top, .trailing], AppTheme.Spacing.sm)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: hasSeenStreakExplainer)
    }

    private var repStreakCell: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(viewModel.loggedStreak)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    viewModel.streakAtRisk    ? AppTheme.Colors.streakDanger :
                    viewModel.loggedStreak > 0 ? AppTheme.Colors.successGreen :
                    Color(UIColor.tertiaryLabel)
                )
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: viewModel.loggedStreak)
            Text("REP STREAK")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
            if viewModel.shouldShowFreezePrompt {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onFreezeRequested?()
                } label: {
                    Text("🧊 Use freeze")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.coolBlue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.Colors.coolBlue.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.3), value: viewModel.shouldShowFreezePrompt)
    }

    private func streakCell(value: Int, label: String, isAtRisk: Bool, activeColor: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    isAtRisk  ? AppTheme.Colors.streakDanger :
                    value > 0 ? activeColor :
                    Color(UIColor.tertiaryLabel)
                )
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: value)
            Text(label)
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
