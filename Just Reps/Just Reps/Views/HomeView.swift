import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel
    @State private var showSettings = false
    @State private var dismissedRecs: Set<String> = []

    private let hkManager = HealthKitManager.shared
    private let weatherManager = WeatherManager.shared

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntries: [WorkoutEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    HeaderCardView(
                        viewModel: viewModel,
                        hkManager: hkManager,
                        weatherManager: weatherManager
                    )
                    stateMessage
                    if viewModel.canMarkRestDay {
                        restDayButton
                    }
                    if viewModel.shouldShowFreezePrompt {
                        freezePromptCard
                    }
                    exerciseCards
                    goalSuggestionsSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .sheet(isPresented: $viewModel.showEffortPicker, onDismiss: {
                viewModel.confirmEffort(nil, context: modelContext)
            }) {
                EffortPickerSheet { effort in
                    viewModel.confirmEffort(effort, context: modelContext)
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .overlay(alignment: .bottom) {
                if viewModel.showCompletionBanner {
                    completionBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(AppTheme.Spacing.md)
                }
            }
            .onChange(of: allEntries) { viewModel.refresh(with: allEntries) }
            .onAppear { viewModel.refresh(with: allEntries) }
            .task {
                weatherManager.requestWeather()
                await hkManager.fetchTrainingLoad()
            }
        }
    }

    // MARK: - State message

    @ViewBuilder
    private var stateMessage: some View {
        let (text, color) = messageContent
        if !text.isEmpty {
            Text(text)
                .font(AppTheme.Font.body())
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.dayState)
        }
    }

    private var messageContent: (String, Color) {
        if viewModel.isRestDay {
            return ("Rest day. See you tomorrow.", Color(UIColor.secondaryLabel))
        }
        if viewModel.streakAtRisk {
            return ("Your streak is at risk. Still time.", AppTheme.Colors.streakDanger)
        }
        switch viewModel.dayState {
        case .fresh:
            return ("Show up. Even 5 reps counts.", Color(UIColor.secondaryLabel))
        case .alive:
            return ("Streak alive. Keep going.", AppTheme.Colors.successGreen)
        case .complete:
            return ("", .clear)
        }
    }

    // MARK: - Exercise cards

    private var exerciseCards: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(viewModel.activeExercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    current: viewModel.totalReps(for: exercise),
                    goal: viewModel.goal(for: exercise),
                    onIncrement: { amount in
                        viewModel.logReps(amount, for: exercise, context: modelContext)
                    }
                )
            }
        }
    }

    // MARK: - Goal suggestions

    private var activeGoalRecs: [GoalRecommendation] {
        GoalAdvisorService.recommendations(
            for: viewModel.activeExercises,
            goals: viewModel.dailyGoals,
            entries: allEntries,
            trainingLoad: hkManager.trainingLoad
        ).filter { !dismissedRecs.contains($0.exercise.rawString) }
    }

    @ViewBuilder
    private var goalSuggestionsSection: some View {
        if !activeGoalRecs.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Suggested Goals".uppercased())
                    .font(AppTheme.Font.caption())
                    .kerning(1)
                    .foregroundStyle(.secondary)
                    .padding(.leading, AppTheme.Spacing.xs)

                ForEach(activeGoalRecs, id: \.exercise.rawString) { rec in
                    GoalSuggestionCard(
                        recommendation: rec,
                        onApply: {
                            viewModel.setGoal(rec.suggestedGoal, for: rec.exercise)
                            withAnimation { _ = dismissedRecs.insert(rec.exercise.rawString) }
                        },
                        onDismiss: {
                            withAnimation { _ = dismissedRecs.insert(rec.exercise.rawString) }
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    // MARK: - Rest day button

    private var restDayButton: some View {
        Button {
            viewModel.markRestDay(context: modelContext)
        } label: {
            Text("Rest day")
                .font(AppTheme.Font.caption())
                .foregroundStyle(Color(UIColor.secondaryLabel))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Freeze prompt

    private var freezePromptCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text("🧊")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Use a freeze?")
                    .font(AppTheme.Font.headline())
                Text("Life happens. Streak protected.")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Use") {
                viewModel.useFreeze(context: modelContext)
            }
            .font(AppTheme.Font.caption().weight(.semibold))
            .foregroundStyle(AppTheme.Colors.coolBlue)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(AppTheme.Colors.coolBlue.opacity(0.12), in: Capsule())
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Completion banner

    private var completionBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.Colors.successGreen)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("All done.")
                    .font(AppTheme.Font.headline())
                Text("Nice work. Now go live your life.")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
