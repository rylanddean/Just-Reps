import SwiftUI
import SwiftData

// Replaces the separate Streak and History tabs with a single unified view.
struct ProgressView: View {
    @Bindable var homeViewModel: HomeViewModel

    @State private var segment = 0
    @State private var streakVM = StreakViewModel()
    @State private var historyVM = HistoryViewModel()
    @State private var selectedPeriod: StreakAnalytics.Period = .weekly
    @State private var showCompleted = false
    @State private var showCreateSheet = false

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutEntry.timestamp)
    private var allEntries: [WorkoutEntry]

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntriesDesc: [WorkoutEntry]

    @Query(sort: \CustomMilestone.createdAt)
    private var customMilestones: [CustomMilestone]

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Streak").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)

                if segment == 0 {
                    streakContent
                        .transition(.opacity)
                } else {
                    historyContent
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: segment)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if segment == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.successGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateMilestoneSheet(activeExercises: streakVM.activeExercises)
            }
        }
        .onChange(of: allEntries) {
            streakVM.refresh(with: allEntries)
            historyVM.refresh(with: allEntriesDesc)
        }
        .onAppear {
            streakVM.refresh(with: allEntries)
            historyVM.refresh(with: allEntriesDesc)
        }
    }

    // MARK: - Streak Content

    private var streakContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                statsRow
                if !streakVM.personalBests.isEmpty { personalBestsSection }
                heatmapSection
                vibesTrendSection
                muscleGroupSection
                if !streakVM.visibleExercises(for: selectedPeriod).isEmpty { progressSection }
                milestonesSection
            }
            .padding(AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(streakVM.currentStreak)", label: "Current")
            Divider().frame(height: 40)
            statCell(value: "\(streakVM.longestStreak)", label: "Longest")
            Divider().frame(height: 40)
            statCell(value: "\(Int(streakVM.monthlyConsistency * 100))%", label: "This Month")
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

    // MARK: - Personal Bests

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Personal Bests")
                .font(AppTheme.Font.headline())

            VStack(spacing: 0) {
                ForEach(Array(streakVM.personalBests.enumerated()), id: \.element.exercise.id) { index, item in
                    if index > 0 { Divider() }
                    personalBestRow(exercise: item.exercise, reps: item.reps)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func personalBestRow(exercise: ExerciseType, reps: Int) -> some View {
        HStack {
            Text(exercise.displayName)
                .font(AppTheme.Font.body())
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(exercise.formattedValue(reps))
                    .font(AppTheme.Font.title())
                    .foregroundStyle(AppTheme.Colors.successGreen)
                    .contentTransition(.numericText())
                Text(exercise.unit)
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Activity")
                .font(AppTheme.Font.headline())

            HeatmapCalendar(
                data: streakVM.heatmapData,
                weeks: 20,
                restDays: streakVM.restDays,
                freezeDays: streakVM.freezeDays,
                canMarkRestDay: homeViewModel.canMarkRestDay,
                onMarkRestDay: { homeViewModel.markRestDay(context: modelContext) }
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
                Spacer()
                HStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(UIColor.systemFill))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(UIColor.separator))
                            .frame(width: 7, height: 2)
                    }
                    .frame(width: 12, height: 12)
                    Text("Rest")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: AppTheme.Spacing.xs) {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(AppTheme.Colors.coolBlue.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                    Text("Freeze")
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Vibes Trend

    private var vibesTrendSection: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Mirror HeatmapCalendar exactly: align to the Sunday 19 weeks back
        let daysSinceSunday = cal.component(.weekday, from: today) - 1
        let thisSunday = cal.date(byAdding: .day, value: -daysSinceSunday, to: today)!
        let startSunday = cal.date(byAdding: .weekOfYear, value: -19, to: thisSunday)!

        // 20 columns (weeks) × 7 rows (Sun–Sat), nil = future date
        let weekColumns: [[Date?]] = (0..<20).map { week in
            (0..<7).map { day -> Date? in
                let d = cal.date(byAdding: .day, value: week * 7 + day, to: startSunday)!
                return d <= today ? d : nil
            }
        }

        // Build a lookup: Date → rating using the same UserDefaults keys as PulseViewModel
        let ratingsMap: [Date: Int] = weekColumns.flatMap { $0 }.compactMap { $0 }
            .reduce(into: [:]) { map, date in
                let c = cal.dateComponents([.year, .month, .day], from: date)
                let key = "pulse.vibes.\(c.year!).\(c.month!).\(c.day!)"
                let n = UserDefaults.standard.integer(forKey: key)
                if n > 0 { map[date] = n }
            }

        let avg: Double? = ratingsMap.isEmpty ? nil
            : Double(ratingsMap.values.reduce(0, +)) / Double(ratingsMap.count)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Vibes")
                    .font(AppTheme.Font.headline())
                Spacer()
                if let avg {
                    Text(String(format: "%.1f avg", avg))
                        .font(AppTheme.Font.caption())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 3) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(["S","M","T","W","T","F","S"].enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 10, height: 12)
                    }
                }
                HStack(alignment: .top, spacing: 3) {
                    ForEach(Array(weekColumns.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 3) {
                            ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                                if let date {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(vibesColor(rating: ratingsMap[date]))
                                        .frame(width: 12, height: 12)
                                } else {
                                    Color.clear.frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Text("Low")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
                ForEach([1, 2, 3, 4, 5], id: \.self) { r in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(vibesColor(rating: r))
                        .frame(width: 12, height: 12)
                }
                Text("High")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("20 weeks")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func vibesColor(rating: Int?) -> Color {
        switch rating {
        case 1: return Color(UIColor.systemFill)
        case 2: return Color(UIColor.tertiaryLabel).opacity(0.4)
        case 3: return AppTheme.Colors.successGreen.opacity(0.25)
        case 4: return AppTheme.Colors.successGreen.opacity(0.6)
        case 5: return AppTheme.Colors.successGreen
        default: return Color(UIColor.systemFill).opacity(0.3)
        }
    }

    // MARK: - Coverage

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Coverage")
                .font(AppTheme.Font.headline())

            let covered = streakVM.muscleGroupCoverageThisWeek
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    let hit = covered.contains(group)
                    Text(group.displayName)
                        .font(AppTheme.Font.caption())
                        .kerning(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(hit ? AppTheme.Colors.successGreen.opacity(0.15) : Color(UIColor.systemFill))
                        .foregroundStyle(hit ? AppTheme.Colors.successGreen : Color(UIColor.secondaryLabel))
                        .clipShape(Capsule())
                }
            }

            Text("This week")
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Progress Sparklines

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

            let buckets = streakVM.buckets(for: selectedPeriod)
            let exercises = StreakAnalytics.visibleExercises(in: buckets)
            let summaries = streakVM.summaries(for: selectedPeriod)

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
                Text(exercise.displayName)
                    .font(AppTheme.Font.body())
                    .fontWeight(.semibold)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(exercise.formattedValue(totalReps))
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

            let allItems = streakVM.milestoneItems(customMilestones: customMilestones)
            let active = allItems.filter { !$0.isCompleted }.sorted { $0.progress > $1.progress }
            let completed = allItems.filter(\.isCompleted)

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
                    ForEach(completed) { milestoneCard($0).opacity(0.5) }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy, value: showCompleted)
    }

    private var milestonesHeader: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Milestones")
                .font(AppTheme.Font.headline())
            Spacer()
            let completedCount = streakVM.milestoneItems(customMilestones: customMilestones).filter(\.isCompleted).count
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
        }
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
                        Capsule().fill(Color(UIColor.systemFill))
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

    // MARK: - History Content

    private var historyContent: some View {
        Group {
            if allEntriesDesc.isEmpty {
                historyEmptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        totalsBanner
                        ForEach(historyVM.groupedByDay, id: \.date) { group in
                            daySection(group)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
    }

    private var totalsBanner: some View {
        VStack(spacing: 4) {
            Text("\(historyVM.totalRepsAllTime)")
                .font(AppTheme.Font.title())
                .contentTransition(.numericText())
            Text("TOTAL REPS")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    private func daySection(_ group: (date: Date, entries: [WorkoutEntry])) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(dayFormatter.string(from: group.date).uppercased())
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                    entryRow(entry)
                    if idx < group.entries.count - 1 {
                        Divider().padding(.leading, AppTheme.Spacing.md)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private func entryRow(_ entry: WorkoutEntry) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind == .rest ? "Rest day" : entry.kind == .freeze ? "Streak freeze" : entry.exercise.displayName)
                    .font(AppTheme.Font.body())
                    .foregroundStyle(entry.kind == .workout ? Color(UIColor.label) : .secondary)
                Text(timeFormatter.string(from: entry.timestamp))
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.kind == .workout {
                Text("\(entry.reps) \(entry.exercise.unit)")
                    .font(AppTheme.Font.headline())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                let timestamp = entry.timestamp
                modelContext.delete(entry)
                if (UserDefaults(suiteName: "group.com.rylanddean.justreps") ?? .standard).bool(forKey: "healthKitEnabled") {
                    Task { await HealthKitManager.shared.deleteWorkout(near: timestamp) }
                }
            } label: {
                Label("Delete entry", systemImage: "trash")
            }
        }
    }

    private var historyEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("💪")
                .font(.system(size: 56))
            Text("No reps yet.")
                .font(AppTheme.Font.title())
            Text("Log your first set on the Today tab.")
                .font(AppTheme.Font.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.xl)
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
                    Divider().padding(.horizontal, AppTheme.Spacing.md)
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

    private var targetStep: Int { metricType == "totalReps" ? 50 : 7 }

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
