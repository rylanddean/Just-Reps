import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel
    @State private var showSettings = false

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntries: [WorkoutEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    headerSection
                    stateMessage
                    exerciseCards
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
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
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text(Date.now.formatted(date: .complete, time: .omitted).uppercased())
                .font(AppTheme.Font.caption())
                .kerning(1.5)
                .foregroundStyle(.secondary)
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
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .frame(maxWidth: .infinity)
    }

    private func streakCell(value: Int, label: String, isAtRisk: Bool, activeColor: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    isAtRisk           ? AppTheme.Colors.streakDanger :
                    value > 0          ? activeColor :
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
            return ("Don't break the chain.", AppTheme.Colors.streakDanger)
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
