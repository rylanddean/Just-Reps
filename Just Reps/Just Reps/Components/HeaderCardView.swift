import SwiftUI

struct HeaderCardView: View {
    var viewModel: HomeViewModel
    var hkManager: HealthKitManager
    var weatherManager: WeatherManager

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
    }

    // MARK: - Context bar

    private var contextBar: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(
                Date.now.formatted(
                    .dateTime.weekday(.abbreviated).month(.abbreviated).day()
                ).uppercased()
            )
            .font(AppTheme.Font.caption())
            .kerning(1.5)
            .foregroundStyle(.secondary)
            .fixedSize()

            Spacer(minLength: AppTheme.Spacing.sm)

            HStack(spacing: AppTheme.Spacing.sm) {
                if weatherManager.hasData {
                    HStack(spacing: 4) {
                        Image(systemName: weatherManager.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 13))
                        Text(weatherManager.temperatureString)
                    }
                }

                if let load = hkManager.trainingLoad {
                    if weatherManager.hasData {
                        Text("·")
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
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Streak cells

    private var streakRow: some View {
        HStack(spacing: 0) {
            streakCell(
                value: viewModel.loggedStreak,
                label: "REP STREAK",
                isAtRisk: viewModel.streakAtRisk,
                activeColor: AppTheme.Colors.successGreen
            )
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
