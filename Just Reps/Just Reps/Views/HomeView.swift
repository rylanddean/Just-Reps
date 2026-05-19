import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel
    @State private var showSettings = false
    @State private var showFreezeConfirm = false

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
                        weatherManager: weatherManager,
                        onFreezeRequested: { showFreezeConfirm = true }
                    )
                    stateMessage
                    exerciseCards
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
            .sheet(isPresented: $showFreezeConfirm) {
                freezeConfirmSheet
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
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

    private var goalRecs: [GoalRecommendation] {
        GoalAdvisorService.recommendations(
            for: viewModel.activeExercises,
            goals: viewModel.dailyGoals,
            entries: allEntries,
            trainingLoad: hkManager.trainingLoad
        )
    }

    private var exerciseCards: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(viewModel.activeExercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    current: viewModel.totalReps(for: exercise),
                    goal: viewModel.goal(for: exercise),
                    onIncrement: { amount in
                        viewModel.logReps(amount, for: exercise, context: modelContext)
                    },
                    recommendation: goalRecs.first { $0.exercise == exercise },
                    onApplyRecommendation: { newGoal in
                        viewModel.setGoal(newGoal, for: exercise)
                    },
                    onGoalChange: { newGoal in
                        viewModel.setGoal(newGoal, for: exercise)
                    }
                )
            }
        }
    }

    // MARK: - Freeze confirm sheet

    private var freezeConfirmSheet: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("🧊")
                .font(.system(size: 40))
                .padding(.top, AppTheme.Spacing.lg)
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Use a freeze?")
                    .font(AppTheme.Font.title())
                    .fontWeight(.bold)
                Text("Life happens. Streak protected.")
                    .font(AppTheme.Font.body())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    viewModel.useFreeze(context: modelContext)
                    showFreezeConfirm = false
                } label: {
                    Text("Use Freeze")
                        .font(AppTheme.Font.headline())
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.Colors.coolBlue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button { showFreezeConfirm = false } label: {
                    Text("Cancel")
                        .font(AppTheme.Font.body())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
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
