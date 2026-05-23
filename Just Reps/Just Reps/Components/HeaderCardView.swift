import SwiftUI

struct HeaderCardView: View {
    var viewModel: HomeViewModel
    var hkManager: HealthKitManager
    var weatherManager: WeatherManager
    var onFreezeRequested: (() -> Void)? = nil

    @AppStorage("hasSeenStreakExplainer") private var hasSeenStreakExplainer = false
    @State private var showExplainer = false

    var body: some View {
        VStack(spacing: 0) {
            contextBar
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 0.5)
            streakRow
        }
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

    // MARK: - Context bar

    private var contextBar: some View {
        VStack(alignment: .center, spacing: AppTheme.Spacing.xs) {
            Text(
                Date.now.formatted(
                    .dateTime.weekday(.abbreviated).month(.abbreviated).day()
                ).uppercased()
            )
            .font(AppTheme.Font.caption())
            .kerning(1.5)
            .foregroundStyle(.secondary)

            if weatherManager.hasData || hkManager.trainingLoad != nil {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if weatherManager.hasData {
                        Image(systemName: weatherManager.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 13))
                        Text(weatherManager.conditionText)
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up")
                            Text(weatherManager.highTemperatureString)
                            Image(systemName: "arrow.down")
                            Text(weatherManager.lowTemperatureString)
                        }
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                    }

                    if let load = hkManager.trainingLoad {
                        if weatherManager.hasData {
                            Text("·")
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                        HStack(spacing: 3) {
                            Text("\(load.todayMinutes) min")
                            if load.trend != .neutral {
                                Image(systemName: load.trend.arrowSymbol)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(
                                        load.trend == .up
                                            ? AppTheme.Colors.successGreen
                                            : Color(UIColor.secondaryLabel)
                                    )
                            }
                        }
                    }
                }
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
                .animation(.easeIn(duration: 0.3), value: weatherManager.hasData)
            }

            if weatherManager.hasData {
                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    HStack(spacing: 3) {
                        Image(systemName: "apple.logo")
                        Text("Weather")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
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
