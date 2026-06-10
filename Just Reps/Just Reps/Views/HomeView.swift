import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel
    @State private var showSettings = false
    @State private var showFreezeConfirm = false
    @State private var showRestDayConfirm = false

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntries: [WorkoutEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    HeaderCardView(
                        viewModel: viewModel,
                        onFreezeRequested: { showFreezeConfirm = true }
                    )
                    stateMessage
                    if viewModel.isRestDay {
                        restDayCard
                    } else {
                        exerciseCards
                        if viewModel.pendingSleepRestSuggestion && viewModel.canMarkRestDay {
                            sleepRestSuggestionCard
                        } else if viewModel.canMarkRestDay {
                            restDayButton
                        }
                    }
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
            .sheet(
                isPresented: Binding(
                    get: { viewModel.pendingEulogy != nil },
                    set: { showing in if !showing { viewModel.dismissEulogy() } }
                )
            ) {
                if let length = viewModel.pendingEulogy {
                    StreakEulogySheet(streakLength: length)
                }
            }
            .sheet(isPresented: $showFreezeConfirm) {
                freezeConfirmSheet
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showRestDayConfirm) {
                restDayConfirmSheet
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: allEntries) { viewModel.refresh(with: allEntries) }
            .onAppear {
                viewModel.refresh(with: allEntries)
                Task { await viewModel.checkSleepAdvice() }
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
                    mvr: viewModel.mvr(for: exercise),
                    onIncrement: { amount in
                        viewModel.logReps(amount, for: exercise, context: modelContext)
                    },
                    onHealthSync: exercise.isAutoTracked ? {
                        Task { await viewModel.syncWalkingEntry(context: modelContext) }
                    } : nil,
                    onGoalChange: { newGoal in
                        viewModel.setGoal(newGoal, for: exercise)
                    }
                )
            }
        }
    }

    // MARK: - Rest day

    private var sleepRestSuggestionCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rough night.")
                    .font(AppTheme.Font.body())
                Text("Rest day?")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.markRestDay(context: modelContext)
                viewModel.dismissSleepRestSuggestion()
            } label: {
                Text("Yes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color(UIColor.label))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button {
                viewModel.dismissSleepRestSuggestion()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                    .padding(AppTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private var restDayCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "moon.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color(UIColor.secondaryLabel))
            Text("Rest day.")
                .font(AppTheme.Font.headline())
            Text("See you tomorrow.")
                .font(AppTheme.Font.body())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private var restDayButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            showRestDayConfirm = true
        } label: {
            Text("Rest day")
                .font(AppTheme.Font.caption())
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color(UIColor.systemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var restDayConfirmSheet: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "moon.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .padding(.top, AppTheme.Spacing.lg)
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Rest day?")
                    .font(AppTheme.Font.title())
                    .fontWeight(.bold)
                Text("One per week. Streak stays intact.")
                    .font(AppTheme.Font.body())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.markRestDay(context: modelContext)
                    showRestDayConfirm = false
                } label: {
                    Text("Take the day")
                        .font(AppTheme.Font.headline())
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(UIColor.systemFill))
                        .foregroundStyle(Color(UIColor.label))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button { showRestDayConfirm = false } label: {
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
