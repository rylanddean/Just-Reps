import SwiftUI
import SwiftData

struct StreakView: View {
    @State private var viewModel = StreakViewModel()
    @State private var selectedPeriod: StreakAnalytics.Period = .weekly
    @State private var showCompleted = false
    @State private var showCreateSheet = false

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutEntry.timestamp)
    private var allEntries: [WorkoutEntry]

    @Query(sort: \CustomMilestone.createdAt)
    private var customMilestones: [CustomMilestone]

    private var allMilestoneItems: [MilestoneItem] {
        viewModel.milestoneItems(customMilestones: customMilestones)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    statsRow
                    heatmapSection
                    if !viewModel.visibleExercises(for: selectedPeriod).isEmpty {
                        progressSection
                    }
                    milestonesSection
                }
                .padding(AppTheme.Spacing.md)
            }
            .navigationTitle("Streak")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: allEntries) { viewModel.refresh(with: allEntries) }
            .onAppear { viewModel.refresh(with: allEntries) }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(viewModel.currentStreak)", label: "Current")
            Divider().frame(height: 40)
            statCell(value: "\(viewModel.longestStreak)", label: "Longest")
            Divider().frame(height: 40)
            statCell(value: "\(Int(viewModel.monthlyConsistency * 100))%", label: "This Month")
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Font.title())
                .foregroundStyle(Color(UIColor.label))
                .contentTransition(.numericText())
            Text(label.uppercased())
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Activity")
                .font(AppTheme.Font.headline())

            HeatmapCalendar(
                data: viewModel.heatmapData,
                weeks: 20,
                restDays: viewModel.restDays,
                freezeDays: viewModel.freezeDays,
                canMarkRestDay: canMarkRestDay,
                onMarkRestDay: markRestDay
            )

            HStack(spacing: AppTheme.Spacing.xs) {
                Text("Less")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(intensity == 0
                              ? Color(UIColor.systemFill)
                              : AppTheme.Colors.successGreen.opacity(intensity))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Progress")
                    .font(AppTheme.Font.headline())
                Spacer()
                Picker("Period", selection: $selectedPeriod) {
                    Text("Week").tag(StreakAnalytics.Period.weekly)
                    Text("Month").tag(StreakAnalytics.Period.monthly)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
            }

            let buckets = viewModel.buckets(for: selectedPeriod)
            let exercises = StreakAnalytics.visibleExercises(in: buckets)
            let summaries = viewModel.summaries(for: selectedPeriod)

            ForEach(exercises, id: \.id) { exercise in
                exerciseProgressCard(
                    exercise: exercise,
                    buckets: buckets,
                    avg: summaries.first { $0.exercise == exercise }?.average ?? 0
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exerciseProgressCard(
        exercise: ExerciseType,
        buckets: [StreakAnalytics.Bucket],
        avg: Double
    ) -> some View {
        let totalReps = buckets.reduce(0) { $0 + $1.totalReps(for: exercise) }
        let maxTotal = max(buckets.map { $0.totalReps(for: exercise) }.max() ?? 1, 1)
        let periodLabel = selectedPeriod == .weekly ? "8-wk avg" : "6-mo avg"

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.emoji)
                Text(exercise.displayName)
                    .font(AppTheme.Font.body())
                    .fontWeight(.semibold)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(totalReps)")
                        .font(AppTheme.Font.title())
                        .foregroundStyle(AppTheme.Colors.successGreen)
                        .contentTransition(.numericText())
                    Text(exercise.unit)
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                    sparklineBar(
                        reps: bucket.totalReps(for: exercise),
                        maxReps: maxTotal,
                        isCurrent: index == buckets.count - 1
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)

            Text("\(periodLabel)  ·  \(avg, specifier: "%.1f") \(exercise.unit)/day")
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func sparklineBar(reps: Int, maxReps: Int, isCurrent: Bool) -> some View {
        let fraction = CGFloat(reps) / CGFloat(max(maxReps, 1))
        return RoundedRectangle(cornerRadius: 2)
            .fill(isCurrent
                  ? AppTheme.Colors.successGreen
                  : AppTheme.Colors.successGreen.opacity(reps > 0 ? 0.35 : 0.1))
            .frame(maxWidth: .infinity)
            .frame(height: max(fraction * 32, reps > 0 ? 2 : 1))
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            milestonesHeader

            let active = allMilestoneItems
                .filter { !$0.isCompleted }
                .sorted { $0.progress > $1.progress }
            let completed = allMilestoneItems.filter(\.isCompleted)

            if active.isEmpty {
                Text(completed.isEmpty ? "Add a milestone to track." : "All milestones completed.")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
                    .padding(.vertical, AppTheme.Spacing.xs)
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(active) { milestoneCard($0) }
                }
            }

            if showCompleted && !completed.isEmpty {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(completed) {
                        milestoneCard($0).opacity(0.5)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showCreateSheet) {
            CreateMilestoneSheet(activeExercises: viewModel.activeExercises)
        }
    }

    private var milestonesHeader: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Milestones")
                .font(AppTheme.Font.headline())
            Spacer()
            let completedCount = allMilestoneItems.filter(\.isCompleted).count
            if completedCount > 0 {
                Button {
                    withAnimation(.snappy) { showCompleted.toggle() }
                } label: {
                    Text(showCompleted ? "Hide" : "\(completedCount) done")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.successGreen)
            }
        }
    }

    // MARK: - Rest day

    private var canMarkRestDay: Bool {
        let today = StreakEngine.logicalDay(for: .now)
        guard !allEntries.contains(where: { $0.kind == .rest && StreakEngine.logicalDay(for: $0.timestamp) == today }) else { return false }
        guard !allEntries.contains(where: { $0.kind == .workout && StreakEngine.logicalDay(for: $0.timestamp) == today }) else { return false }
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: .now)!
        return allEntries.filter { $0.kind == .rest && $0.timestamp >= cutoff }.isEmpty
    }

    private func markRestDay() {
        modelContext.insert(WorkoutEntry(kind: .rest))
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func milestoneCard(_ item: MilestoneItem) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(item.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(item.title)
                        .font(AppTheme.Font.caption())
                        .fontWeight(.semibold)
                    Spacer()
                    Text(item.progressLabel)
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemFill))
                        Capsule()
                            .fill(AppTheme.Colors.successGreen)
                            .frame(width: geo.size.width * item.progress)
                            .animation(.easeOut, value: item.progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .contextMenu {
            if item.isCustom, let milestone = item.customMilestone {
                Button(role: .destructive) {
                    modelContext.delete(milestone)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Create Milestone Sheet

private struct CreateMilestoneSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let activeExercises: [ExerciseType]

    @State private var title = ""
    @State private var metricType = "repStreak"
    @State private var selectedExercise: ExerciseType
    @State private var target = 30

    init(activeExercises: [ExerciseType]) {
        let exercises = activeExercises.isEmpty ? ExerciseType.defaults : activeExercises
        self.activeExercises = exercises
        _selectedExercise = State(initialValue: exercises.first ?? .pushups)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    nameCard
                    metricCard
                    targetCard
                }
                .padding(AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("New Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || target < 1)
                }
            }
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("NAME")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            TextField("My milestone", text: $title)
                .font(AppTheme.Font.body())
                .padding(AppTheme.Spacing.md)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private var metricCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("METRIC")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            VStack(spacing: 0) {
                Picker("Type", selection: $metricType) {
                    Text("Rep Streak").tag("repStreak")
                    Text("Goal Streak").tag("goalStreak")
                    Text("Total Reps").tag("totalReps")
                }
                .pickerStyle(.segmented)
                .padding(AppTheme.Spacing.md)

                if metricType == "totalReps" {
                    Divider()
                        .padding(.horizontal, AppTheme.Spacing.md)

                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(activeExercises, id: \.id) { ex in
                            Text("\(ex.emoji) \(ex.displayName)").tag(ex)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TARGET")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            HStack(spacing: AppTheme.Spacing.lg) {
                Button {
                    target = max(1, target - targetStep)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.tertiarySystemBackground), in: Circle())
                        .foregroundStyle(Color(UIColor.label))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(target)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.2), value: target)
                    Text(targetUnit)
                        .font(AppTheme.Font.body())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    target = min(9999, target + targetStep)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.tertiarySystemBackground), in: Circle())
                        .foregroundStyle(Color(UIColor.label))
                }
                .buttonStyle(.plain)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private var targetUnit: String {
        switch metricType {
        case "repStreak", "goalStreak": return target == 1 ? "day" : "days"
        default: return selectedExercise.unit
        }
    }

    private var targetStep: Int {
        metricType == "totalReps" ? 50 : 7
    }

    private func save() {
        let raw = metricType == "totalReps" ? selectedExercise.rawString : nil
        let milestone = CustomMilestone(
            title: title.trimmingCharacters(in: .whitespaces),
            metricType: metricType,
            exerciseRaw: raw,
            target: target
        )
        modelContext.insert(milestone)
        dismiss()
    }
}
