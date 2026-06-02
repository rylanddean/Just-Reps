import SwiftUI
import SwiftData

struct PulseView: View {
    var homeViewModel: HomeViewModel

    @AppStorage("userName") private var userName = ""
    @State private var viewModel = PulseViewModel()
    @State private var streakVM = StreakViewModel()
    @State private var setupComplete = false
    @State private var showChat = false

    private let weatherManager = WeatherManager.shared
    private let hkManager = HealthKitManager.shared

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntries: [WorkoutEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    headerSection

                    if viewModel.isAIAvailable {
                        insightCard
                    }

                    vibesCard

                    if !goalRecs.isEmpty {
                        goalRecsSection
                    }

                    if viewModel.isAIAvailable {
                        chatTrigger
                    } else if !viewModel.messages.isEmpty {
                        inlineAssistantMessages
                    }
                }
                .padding(AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            async let weather: () = weatherManager.fetchIfNeeded()
            async let training: () = hkManager.fetchTrainingLoad()
            _ = await (weather, training)
            streakVM.refresh(with: allEntries)
            await viewModel.setup(contextSummary: buildContext())
            setupComplete = true
        }
        .onChange(of: allEntries) {
            streakVM.refresh(with: allEntries)
        }
        .onChange(of: viewModel.vibesRating) { _, newRating in
            guard setupComplete, newRating == 1 else { return }
            reactToLowVibe()
        }
        .sheet(isPresented: $showChat, onDismiss: { viewModel.clearMessages() }) {
            PulseChatSheet(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(formattedDate)
                .font(AppTheme.Font.caption())
                .kerning(0.5)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            let name = userName.trimmingCharacters(in: .whitespaces)
            let streak = streakVM.currentStreak

            if !name.isEmpty {
                Text("\(name).")
                    .font(AppTheme.Font.title())
                    .foregroundStyle(Color(UIColor.label))
                if streak > 0 {
                    Text("Day \(streak).")
                        .font(AppTheme.Font.headline())
                        .foregroundStyle(AppTheme.Colors.successGreen)
                }
            } else {
                if streak > 0 {
                    Text("Day \(streak).")
                        .font(AppTheme.Font.title())
                        .foregroundStyle(AppTheme.Colors.successGreen)
                } else {
                    Text("Start your streak.")
                        .font(AppTheme.Font.title())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - AI insight card

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.successGreen)
                Text("PULSE")
                    .font(AppTheme.Font.caption())
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isGeneratingInsight {
                Text("You've been consistent this week. Your recent sessions are building a reliable habit.")
                    .font(AppTheme.Font.body())
                    .lineSpacing(4)
                    .redacted(reason: .placeholder)
            } else if !viewModel.dailyInsight.isEmpty {
                Text(viewModel.dailyInsight)
                    .font(AppTheme.Font.body())
                    .lineSpacing(4)
                    .transition(.opacity)
            }

            if weatherManager.hasData {
                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    HStack(spacing: 2) {
                        Image(systemName: "apple.logo")
                        Text("Weather")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(Color(UIColor.quaternaryLabel))
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .animation(.easeIn(duration: 0.3), value: viewModel.isGeneratingInsight)
    }

    // MARK: - Vibes

    private var vibesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                let name = userName.trimmingCharacters(in: .whitespaces)
                Text(name.isEmpty ? "How do you feel today?" : "How do you feel today, \(name)?")
                    .font(AppTheme.Font.headline())
                Spacer()
                if let rating = viewModel.vibesRating {
                    Text(vibesLabel(rating))
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
                }
            }

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { n in
                    vibesDot(n)
                }
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .animation(.spring(duration: 0.25), value: viewModel.vibesRating)
    }

    private func vibesDot(_ value: Int) -> some View {
        let selected = viewModel.vibesRating == value
        return Circle()
            .fill(selected ? AppTheme.Colors.successGreen : Color(UIColor.systemFill))
            .frame(width: 40, height: 40)
            .overlay {
                Text("\(value)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? Color.black : Color(UIColor.secondaryLabel))
            }
            .scaleEffect(selected ? 1.12 : 1.0)
            .animation(.spring(duration: 0.2), value: selected)
            .onTapGesture { viewModel.setVibes(value) }
    }

    private func vibesLabel(_ n: Int) -> String {
        switch n {
        case 1: return "Rough"
        case 2: return "Okay"
        case 3: return "Solid"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }

    // MARK: - Goal recommendations

    private var goalRecs: [GoalRecommendation] {
        GoalAdvisorService.recommendations(
            for: homeViewModel.activeExercises,
            goals: homeViewModel.dailyGoals,
            entries: allEntries,
            trainingLoad: hkManager.trainingLoad
        )
    }

    private var goalRecsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Goal suggestions")
                .font(AppTheme.Font.headline())

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(goalRecs, id: \.exercise.id) { rec in
                    goalRecRow(rec)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func goalRecRow(_ rec: GoalRecommendation) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: rec.direction == .increase ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(rec.direction == .increase
                                 ? AppTheme.Colors.successGreen
                                 : Color(UIColor.secondaryLabel))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(rec.exercise.displayName)
                    .font(AppTheme.Font.body())
                Text(rec.headline)
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: AppTheme.Spacing.xs) {
                Text("\(rec.currentGoal) → \(rec.suggestedGoal)")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    homeViewModel.setGoal(rec.suggestedGoal, for: rec.exercise)
                } label: {
                    Text("Apply")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.successGreen)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.successGreen.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chat trigger

    private var chatTrigger: some View {
        Button { showChat = true } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "waveform")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.successGreen)
                Text("Ask Pulse")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(Color(UIColor.label))
                Spacer()
                if !viewModel.messages.isEmpty {
                    Circle()
                        .fill(AppTheme.Colors.successGreen)
                        .frame(width: 7, height: 7)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
            .padding(AppTheme.Spacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Non-AI inline messages (injected vibe reactions for non-Apple Intelligence devices)

    private var inlineAssistantMessages: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(viewModel.messages.filter { $0.role == .assistant }) { msg in
                Text(msg.content)
                    .font(AppTheme.Font.body())
                    .lineSpacing(3)
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            }
        }
    }

    // MARK: - Vibe reaction

    private func reactToLowVibe() {
        let alreadySuggested = viewModel.messages.contains {
            $0.role == .assistant && ($0.content.contains("rest day") || $0.content.contains("freeze"))
        }
        guard !alreadySuggested else { return }

        let hasFreezeToken = homeViewModel.freezeTokens > 0
        let isAlreadyResting = homeViewModel.isRestDay
        let streakAtRisk = homeViewModel.streakAtRisk

        let message: String
        if isAlreadyResting {
            message = "Rest day logged. Take it easy."
        } else if streakAtRisk && hasFreezeToken {
            message = "Rough day. Your streak is at risk — you can use a freeze token to protect it, or log a rest day from the Log tab. One rest day per week keeps the streak intact."
        } else if hasFreezeToken {
            message = "Rough day. Head to the Log tab if you want to mark a rest day. You also have a freeze token available if you need it."
        } else {
            message = "Rough day. Head to the Log tab and mark it as a rest day — one per week, and your streak stays intact."
        }
        viewModel.injectAssistantMessage(message)
    }

    // MARK: - Context builder

    private func buildContext() -> String {
        let cal = Calendar.current
        let streak = streakVM.currentStreak
        let longest = streakVM.longestStreak
        let workouts = allEntries.filter { $0.kind == .workout }
        let totalReps = workouts.reduce(0) { $0 + $1.reps }

        let last7 = workouts.filter {
            (cal.dateComponents([.day], from: $0.timestamp, to: .now).day ?? 8) <= 7
        }
        let last7Reps = last7.reduce(0) { $0 + $1.reps }
        let activeDaysLast7 = Set(last7.map { cal.startOfDay(for: $0.timestamp) }).count

        let todayWorkouts = workouts.filter { cal.isDateInToday($0.timestamp) }
        let repsByExercise = todayWorkouts.reduce(into: [String: Int]()) { acc, entry in
            acc[entry.exercise.displayName, default: 0] += entry.reps
        }
        let todaySummary = repsByExercise
            .sorted { $0.key < $1.key }
            .map { "\($0.value) \($0.key)" }
            .joined(separator: ", ")

        let defaults = UserDefaults(suiteName: "group.com.rylanddean.justreps") ?? .standard
        let exercises = defaults.stringArray(forKey: "activeExercises")?.joined(separator: ", ") ?? ""

        let name = userName.trimmingCharacters(in: .whitespaces)
        var parts: [String] = []
        if !name.isEmpty { parts.append("User's name: \(name).") }
        parts += [
            "Current streak: \(streak) days.",
            "Longest streak: \(longest) days.",
            "Total reps all time: \(totalReps).",
            "Last 7 days: \(last7Reps) reps across \(activeDaysLast7) active days.",
        ]
        if !exercises.isEmpty { parts.append("Active exercises: \(exercises).") }
        if !todaySummary.isEmpty { parts.append("Today logged: \(todaySummary).") }
        if let v = viewModel.vibesRating { parts.append("Today's vibe: \(v)/5.") }

        if weatherManager.hasData {
            var w = "Weather: \(weatherManager.conditionText), \(weatherManager.temperatureString) now, high \(weatherManager.highTemperatureString), low \(weatherManager.lowTemperatureString)"
            if weatherManager.precipitationChance > 10 {
                w += ", \(weatherManager.precipitationChance)% chance of rain"
            }
            parts.append(w + ".")
        }
        if let load = hkManager.trainingLoad {
            let trendText = load.trend == .up ? "trending up" : load.trend == .down ? "trending down" : "stable"
            parts.append("Training load: \(load.todayMinutes) active minutes today, overall load is \(trendText) this week.")
        }
        let recs = goalRecs
        if !recs.isEmpty {
            let recSummary = recs.map { "\($0.exercise.displayName): \($0.currentGoal) → \($0.suggestedGoal)" }.joined(separator: ", ")
            parts.append("Pending goal suggestions: \(recSummary).")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: .now)
    }
}

// MARK: - Chat sheet

private struct PulseChatSheet: View {
    var viewModel: PulseViewModel
    @Environment(\.dismiss) private var dismiss
    @Namespace private var bottomAnchor

    private let starters: [(icon: String, text: String)] = [
        ("chart.line.uptrend.xyaxis", "How am I doing this week?"),
        ("figure.strengthtraining.traditional", "What muscles am I neglecting?"),
        ("target", "Help me set better goals."),
        ("hand.raised.fill", "How do I improve my pushup form?"),
        ("calendar.badge.checkmark", "Why does showing up every day matter?"),
        ("plus.circle", "What should I add to my routine?"),
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        if !viewModel.messages.isEmpty {
                            messagesThread
                                .onChange(of: viewModel.messages.count) {
                                    withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(bottomAnchor) }
                                }
                                .onChange(of: viewModel.isSendingMessage) {
                                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(bottomAnchor) }
                                }
                        }

                        conversationStarters

                        Color.clear.frame(height: 1).id(bottomAnchor)
                    }
                    .padding(AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var messagesThread: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(viewModel.messages) { msg in
                messageBubble(msg)
            }
            if viewModel.isSendingMessage {
                HStack {
                    TypingIndicatorView()
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.isSendingMessage)
    }

    private func messageBubble(_ msg: PulseMessage) -> some View {
        HStack(alignment: .bottom) {
            if msg.role == .user { Spacer(minLength: 56) }
            Text(msg.content)
                .font(AppTheme.Font.body())
                .lineSpacing(3)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    msg.role == .user
                        ? AppTheme.Colors.successGreen.opacity(0.15)
                        : Color(UIColor.secondarySystemBackground)
                )
                .foregroundStyle(Color(UIColor.label))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            if msg.role == .assistant { Spacer(minLength: 56) }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var conversationStarters: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("What to discuss")
                .font(AppTheme.Font.headline())

            VStack(spacing: 0) {
                ForEach(starters, id: \.text) { starter in
                    Button {
                        viewModel.inputText = starter.text
                        Task { await viewModel.sendMessage() }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: starter.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.Colors.successGreen)
                                .frame(width: 18)
                            Text(starter.text)
                                .font(AppTheme.Font.body())
                                .foregroundStyle(Color(UIColor.label))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if starter.text != starters.last?.text {
                        Divider().padding(.leading, AppTheme.Spacing.md + 18 + AppTheme.Spacing.md)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }
}

// MARK: - Typing indicator

private struct TypingIndicatorView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(UIColor.secondaryLabel))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animate ? 1.4 : 1.0)
                    .opacity(animate ? 1 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .onAppear { animate = true }
    }
}
