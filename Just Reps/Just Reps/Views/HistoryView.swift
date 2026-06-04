import SwiftUI
import SwiftData

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutEntry.timestamp, order: .reverse)
    private var allEntries: [WorkoutEntry]

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
            Group {
                if allEntries.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: allEntries) { viewModel.refresh(with: allEntries) }
            .onAppear { viewModel.refresh(with: allEntries) }
        }
    }

    // MARK: - List content

    private var listContent: some View {
        List {
            Section {
                totalsBanner
                    .padding(.vertical, AppTheme.Spacing.sm)
            }

            ForEach(viewModel.groupedByDay, id: \.date) { group in
                Section {
                    ForEach(group.entries) { entry in
                        entryRow(entry)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(dayFormatter.string(from: group.date).uppercased())
                        .font(AppTheme.Font.caption())
                        .kerning(1)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Totals banner

    private var totalsBanner: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.totalRepsAllTime)")
                .font(AppTheme.Font.title())
                .contentTransition(.numericText())
            Text("TOTAL REPS")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Entry row

    private func entryRow(_ entry: WorkoutEntry) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(entry.kind == .rest ? "😴" : entry.kind == .freeze ? "❄️" : entry.exercise.emoji)
                .font(.title3)
                .frame(width: 36, alignment: .center)

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
        .padding(.vertical, AppTheme.Spacing.sm)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 56 }
    }

    // MARK: - Delete

    private func deleteEntry(_ entry: WorkoutEntry) {
        let timestamp = entry.timestamp
        modelContext.delete(entry)
        if (UserDefaults(suiteName: "group.com.rylanddean.justreps") ?? .standard).bool(forKey: "healthKitEnabled") {
            Task { await HealthKitManager.shared.deleteWorkout(near: timestamp) }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("💪")
                .font(.system(size: 56))
            Text("No reps yet.")
                .font(AppTheme.Font.title())
            Text("Log your first set on the Home tab.")
                .font(AppTheme.Font.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
}
