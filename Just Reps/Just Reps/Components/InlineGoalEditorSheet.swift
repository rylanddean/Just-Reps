import SwiftUI

struct InlineGoalEditorSheet: View {
    let exercise: ExerciseType
    let currentGoal: Int
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @FocusState private var focused: Bool

    private var presets: [Int] {
        switch exercise.unit {
        case "steps":    return [2000, 5000, 7500, 10000, 12500, 15000]
        case "sec":      return [30, 60, 90, 120, 180, 300]
        case "sessions": return [1, 2, 3, 5, 7, 10]
        default:         return [25, 50, 75, 100, 150, 200]
        }
    }

    private var parsedGoal: Int? {
        guard let n = Int(input), n > 0, n != currentGoal else { return nil }
        return n
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Daily goal · \(exercise.displayName)")
                .font(AppTheme.Font.headline())
                .padding(.top, AppTheme.Spacing.lg)

            presetGrid

            Divider()
                .padding(.horizontal, AppTheme.Spacing.md)

            customEntryRow

            Spacer()
        }
        .onAppear { input = "\(currentGoal)" }
    }

    // MARK: - Preset chips

    private var presetGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 3),
            spacing: AppTheme.Spacing.sm
        ) {
            ForEach(presets, id: \.self) { preset in
                let isActive = preset == currentGoal
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onConfirm(preset)
                    dismiss()
                } label: {
                    Text(chipLabel(preset))
                        .font(AppTheme.Font.caption())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            isActive
                                ? AppTheme.Colors.successGreen.opacity(0.15)
                                : Color(UIColor.systemFill)
                        )
                        .foregroundStyle(
                            isActive
                                ? AppTheme.Colors.successGreen
                                : Color(UIColor.secondaryLabel)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            isActive
                                ? Capsule().strokeBorder(AppTheme.Colors.successGreen.opacity(0.4), lineWidth: 1)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func chipLabel(_ value: Int) -> String {
        if exercise.unit == "steps" && value >= 1000 {
            return "\(value / 1000)k steps"
        }
        return "\(value) \(exercise.unit)"
    }

    // MARK: - Custom entry

    private var customEntryRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            TextField("\(currentGoal)", text: $input)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($focused)
                .frame(width: 100)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color(UIColor.systemFill), in: RoundedRectangle(cornerRadius: AppTheme.Radius.small))

            Text(exercise.unit)
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                if let goal = parsedGoal {
                    onConfirm(goal)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                }
            } label: {
                Text("Set goal")
                    .font(AppTheme.Font.headline())
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .frame(height: 44)
                    .background(parsedGoal != nil
                                ? Color(UIColor.label)
                                : Color(UIColor.systemFill))
                    .foregroundStyle(parsedGoal != nil
                                     ? Color(UIColor.systemBackground)
                                     : Color(UIColor.secondaryLabel))
                    .clipShape(Capsule())
            }
            .disabled(parsedGoal == nil)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}
