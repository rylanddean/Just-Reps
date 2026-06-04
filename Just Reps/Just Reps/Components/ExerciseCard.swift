import SwiftUI

struct ExerciseCard: View {
    let exercise: ExerciseType
    let current: Int
    let goal: Int
    var mvr: Int = 0
    let onIncrement: (Int) -> Void
    var onHealthSync: (() -> Void)? = nil
    var recommendation: GoalRecommendation? = nil
    var onApplyRecommendation: ((Int) -> Void)? = nil
    var onGoalChange: ((Int) -> Void)? = nil

    @State private var showCustomEntry = false
    @State private var showGoalEditor = false
    @State private var recDismissed = false
    @State private var isExpanded = true
    @State private var timerStart: Date? = nil

    private var progress: Double { min(Double(current) / Double(goal), 1.0) }
    private var isComplete: Bool { current >= goal }
    private var progressColor: Color { AppTheme.Colors.successGreen }
    private var activeRec: GoalRecommendation? { recDismissed ? nil : recommendation }

    var body: some View {
        Group {
            if isComplete && !isExpanded {
                doneRow
            } else {
                fullCard
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isComplete && !isExpanded)
        .sheet(isPresented: $showCustomEntry) {
            CardCustomRepEntry(exercise: exercise) { amount in
                onIncrement(amount)
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGoalEditor) {
            InlineGoalEditorSheet(exercise: exercise, currentGoal: goal) { newGoal in
                onGoalChange?(newGoal)
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: isComplete) { _, complete in
            if complete {
                timerStart = nil
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isExpanded = false
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .onChange(of: recommendation?.exercise.rawString) {
            recDismissed = false
        }
    }

    // MARK: - Done row

    private var doneRow: some View {
        Button { withAnimation { isExpanded = true } } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exercise.displayName)
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(Color(UIColor.label))
                Spacer()
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.successGreen)
                    Text("\(current) \(exercise.unit)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.successGreen)
                        .contentTransition(.numericText())
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Full card

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            headerRow
            progressBar
            if let rec = activeRec {
                inlineRecommendation(rec)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if exercise.isAutoTracked {
                healthSyncFooter
            } else if exercise.isTimerBased {
                timerControls
            } else {
                incrementButtons
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activeRec == nil)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: AppTheme.Spacing.sm) {
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
                Button { showGoalEditor = true } label: {
                    Text("/ \(goal)")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
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
                if mvr > 0 && mvr < goal {
                    let mvrX = geo.size.width * Double(mvr) / Double(goal)
                    Rectangle()
                        .fill(Color(UIColor.label).opacity(0.25))
                        .frame(width: 1.5, height: 14)
                        .offset(x: mvrX - 0.75)
                }
            }
        }
        .frame(height: 8)
    }

    // MARK: - Inline recommendation

    private func inlineRecommendation(_ rec: GoalRecommendation) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: rec.direction == .increase ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(rec.direction == .increase
                                 ? AppTheme.Colors.successGreen
                                 : Color(UIColor.secondaryLabel))

            Text("Suggested: \(rec.suggestedGoal) \(exercise.unit)")
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onApplyRecommendation?(rec.suggestedGoal)
                withAnimation { recDismissed = true }
            } label: {
                Text("Apply")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.successGreen)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.successGreen.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { recDismissed = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Health sync footer (walking / auto-tracked exercises)

    private var healthSyncFooter: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundStyle(.pink)
            Text("Synced from Apple Health")
                .font(AppTheme.Font.caption())
                .foregroundStyle(Color(UIColor.secondaryLabel))
            Spacer()
            if let sync = onHealthSync {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    sync()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                        .padding(AppTheme.Spacing.sm)
                        .background(Color(UIColor.tertiarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Timer controls

    @ViewBuilder
    private var timerControls: some View {
        if let start = timerStart {
            TimelineView(.periodic(from: start, by: 1.0)) { context in
                let elapsed = Int(context.date.timeIntervalSince(start))
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(formatElapsed(elapsed))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.Colors.successGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        if let s = timerStart {
                            let secs = max(1, Int(Date().timeIntervalSince(s)))
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if current + secs >= goal {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                            onIncrement(secs)
                            timerStart = nil
                        }
                    } label: {
                        Text("Stop")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .foregroundStyle(Color(UIColor.label))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                timerStart = Date()
            } label: {
                Text("Start")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .foregroundStyle(Color(UIColor.label))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)s"
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
                Image(systemName: "number")
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
