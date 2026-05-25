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
                    scrollContent
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: allEntries) { viewModel.refresh(with: allEntries) }
            .onAppear { viewModel.refresh(with: allEntries) }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                totalsBanner

                ForEach(viewModel.groupedByDay, id: \.date) { group in
                    daySection(group)
                }
            }
            .padding(AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
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
        .padding(AppTheme.Spacing.lg)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Day section

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
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    // MARK: - Entry row

    private func entryRow(_ entry: WorkoutEntry) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(entry.exercise.emoji)
                .font(.title3)
                .frame(width: 36, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise.displayName)
                    .font(AppTheme.Font.body())
                Text(timeFormatter.string(from: entry.timestamp))
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.reps) \(entry.exercise.unit)")
                .font(AppTheme.Font.headline())
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
