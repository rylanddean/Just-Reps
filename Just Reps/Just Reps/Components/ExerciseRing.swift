import SwiftUI

struct ExerciseRing: View {
    let exercise: ExerciseType
    let current: Int
    let goal: Int
    let onIncrement: (Int) -> Void

    @State private var pressed = false
    @State private var showCustomEntry = false
    @State private var customInput = ""

    private var progress: Double { min(Double(current) / Double(goal), 1.0) }
    private var isComplete: Bool { current >= goal }
    private var ringColor: Color {
        isComplete ? AppTheme.Colors.successGreen : AppTheme.Colors.coolBlue
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ringBody
            incrementButtons
        }
        .sheet(isPresented: $showCustomEntry) {
            CustomRepEntry(exercise: exercise) { amount in
                onIncrement(amount)
                if current + amount >= goal {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Ring

    private var ringBody: some View {
        GeometryReader { geo in
            let size = geo.size.width
            let lineWidth = size * 0.085

            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemFill), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: progress)

                if isComplete {
                    Circle()
                        .stroke(AppTheme.Colors.successGreen.opacity(0.2), lineWidth: lineWidth)
                        .scaleEffect(1.08)
                }

                centerContent(size: size)
            }
            .frame(width: size, height: size)
            .scaleEffect(pressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: pressed)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        let defaultIncrement = exercise.quickIncrements[1]
                        onIncrement(defaultIncrement)
                        if current + defaultIncrement >= goal {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func centerContent(size: CGFloat) -> some View {
        VStack(spacing: size * 0.04) {
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.successGreen)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(exercise.emoji)
                    .font(.system(size: size * 0.18))
                    .transition(.scale.combined(with: .opacity))
            }

            Text("\(current)")
                .font(.system(size: size * 0.22, weight: .heavy, design: .rounded))
                .foregroundStyle(isComplete ? AppTheme.Colors.successGreen : Color(UIColor.label))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: current)

            Text("/ \(goal) \(exercise.unit)")
                .font(.system(size: size * 0.1, weight: .medium))
                .foregroundStyle(Color(UIColor.secondaryLabel))
        }
        .animation(.spring(duration: 0.3), value: isComplete)
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
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundStyle(Color(UIColor.label))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Custom amount entry
            Button {
                customInput = ""
                showCustomEntry = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Custom rep entry sheet

private struct CustomRepEntry: View {
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
