import SwiftUI
import WatchKit

struct WatchGoalSuggestionsView: View {
    var vm: WatchViewModel
    @State private var dismissedRecs: Set<String> = []

    private var activeRecs: [WatchGoalRec] {
        vm.goalRecommendations.filter { !dismissedRecs.contains($0.exercise.rawString) }
    }

    var body: some View {
        if activeRecs.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(WatchTheme.successGreen)
                Text("Goals look good.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(activeRecs, id: \.exercise.rawString) { rec in
                        WatchGoalRecCard(
                            rec: rec,
                            onApply: {
                                vm.applyGoalRecommendation(rec)
                                _ = dismissedRecs.insert(rec.exercise.rawString)
                            },
                            onDismiss: {
                                _ = dismissedRecs.insert(rec.exercise.rawString)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }
}

private struct WatchGoalRecCard: View {
    let rec: WatchGoalRec
    let onApply: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rec.exercise.emoji)
                Text(rec.exercise.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: rec.increase ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())
                    .foregroundStyle(rec.increase ? WatchTheme.successGreen : WatchTheme.streakDanger)
            }

            HStack(spacing: 4) {
                Text("\(rec.currentGoal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text("\(rec.suggestedGoal)")
                    .font(.caption.bold())
            }

            HStack(spacing: 6) {
                Button("Apply") {
                    WKInterfaceDevice.current().play(.success)
                    onApply()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(WatchTheme.successGreen.opacity(0.2))
                .clipShape(Capsule())

                Button("Skip") { onDismiss() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
