import SwiftUI

struct ExerciseCard: View {
    let exercise: ExerciseType
    let current: Int
    let goal: Int
    let onIncrement: (Int) -> Void

    @State private var showCustomEntry = false

    private var progress: Double { min(Double(current) / Double(goal), 1.0) }
    private var isComplete: Bool { current >= goal }
    private var progressColor: Color { AppTheme.Colors.successGreen }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            headerRow
            progressBar
            incrementButtons
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .sheet(isPresented: $showCustomEntry) {
            CardCustomRepEntry(exercise: exercise) { amount in
                onIncrement(amount)
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exercise.emoji)
                    .font(.title2)
                Text(exercise.displayName)
                    .font(AppTheme.Font.headline())
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(current)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(isComplete ? AppTheme.Colors.successGreen : Color(UIColor.label))
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: current)
                Text("/ \(goal)")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(UIColor.systemFill))
                    .frame(height: 8)
                if progress > 0 {
                    Capsule()
                        .fill(progressColor)
                        .frame(width: max(geo.size.width * progress, 16), height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
        }
        .frame(height: 8)
    }

    // MARK: - Increment buttons

    private var incrementButtons: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(exercise.quickIncrements, id: \.self) { inc in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onIncrement(inc)
                    if current + inc >= goal {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    Text("+\(inc)")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .foregroundStyle(Color(UIColor.label))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button { showCustomEntry = true } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Custom rep entry sheet

private struct CardCustomRepEntry: View {
    let exercise: ExerciseType
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @FocusState private var focused: Bool

    private var parsedAmount: Int? {
        guard let n = Int(input), n > 0 else { return nil }
        return n
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Custom \(exercise.displayName)")
                .font(AppTheme.Font.headline())
                .padding(.top, AppTheme.Spacing.lg)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                TextField("0", text: $input)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .frame(maxWidth: 160)

                Text(exercise.unit)
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(.secondary)
            }

            Button {
                if let amount = parsedAmount {
                    onConfirm(amount)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                }
            } label: {
                Text("Log \(input.isEmpty ? "" : "+\(input)")")
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(parsedAmount != nil
                                ? Color(UIColor.label)
                                : Color(UIColor.systemFill))
                    .foregroundStyle(parsedAmount != nil
                                     ? Color(UIColor.systemBackground)
                                     : Color(UIColor.secondaryLabel))
                    .clipShape(Capsule())
            }
            .disabled(parsedAmount == nil)
            .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()
        }
        .onAppear { focused = true }
    }
}
