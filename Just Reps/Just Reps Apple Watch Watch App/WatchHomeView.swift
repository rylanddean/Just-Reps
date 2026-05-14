import SwiftUI
import SwiftData
import WatchKit

struct WatchHomeView: View {
    var vm: WatchViewModel
    var context: ModelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(vm.activeExercises) { exercise in
                    WatchExerciseCard(exercise: exercise, vm: vm, context: context)
                }

                if vm.allGoalsMet {
                    Text("Done. That's all it takes.")
                        .font(.caption2)
                        .foregroundStyle(WatchTheme.successGreen)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
}

struct WatchExerciseCard: View {
    let exercise: ExerciseType
    var vm: WatchViewModel
    var context: ModelContext

    private var reps: Int    { vm.totalReps(for: exercise) }
    private var done: Bool   { vm.goalMet(for: exercise) }
    private var progress: Double { vm.progress(for: exercise) }
    private var accentColor: Color { done ? WatchTheme.successGreen : WatchTheme.coolBlue }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: name + rep count
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(exercise.emoji)
                    .font(.body)
                Text(exercise.displayName)
                    .font(.headline)
                Spacer()
                Text("\(reps)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(done ? WatchTheme.successGreen : .primary)
                    .contentTransition(.numericText())
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            // Quick-add buttons
            HStack(spacing: 5) {
                ForEach(exercise.quickIncrements, id: \.self) { amount in
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        vm.logReps(amount, for: exercise, context: context)
                    } label: {
                        Text("+\(amount)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .background(accentColor.opacity(done ? 0.25 : 0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
