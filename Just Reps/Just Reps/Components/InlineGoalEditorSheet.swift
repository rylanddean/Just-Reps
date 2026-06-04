import SwiftUI

struct InlineGoalEditorSheet: View {
    let exercise: ExerciseType
    let currentGoal: Int
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @FocusState private var focused: Bool

    private var parsedGoal: Int? {
        if exercise.usesDecimalDisplay {
            // Distance mode: user types "5.2", store as 52 (× 10)
            guard let d = Double(input), d > 0 else { return nil }
            let scaled = Int((d * 10).rounded())
            return scaled != currentGoal ? scaled : nil
        }
        guard let n = Int(input), n > 0, n != currentGoal else { return nil }
        return n
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Daily goal · \(exercise.displayName)")
                .font(AppTheme.Font.headline())
                .padding(.top, AppTheme.Spacing.lg)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                TextField(exercise.formattedValue(currentGoal), text: $input)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .keyboardType(exercise.usesDecimalDisplay ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .frame(maxWidth: 160)

                Text(exercise.unit)
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(.secondary)
            }

            Button {
                if let goal = parsedGoal {
                    onConfirm(goal)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                }
            } label: {
                Text("Set Goal")
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(parsedGoal != nil
                                ? Color(UIColor.label)
                                : Color(UIColor.systemFill))
                    .foregroundStyle(parsedGoal != nil
                                     ? Color(UIColor.systemBackground)
                                     : Color(UIColor.secondaryLabel))
                    .clipShape(Capsule())
            }
            .disabled(parsedGoal == nil)
            .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()
        }
        .onAppear { focused = true }
    }
}
