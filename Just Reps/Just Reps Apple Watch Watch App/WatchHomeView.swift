import SwiftUI
import WatchKit

struct WatchHomeView: View {
    var vm: WatchViewModel
    @State private var wasAllGoalsMet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Text("🔥 \(vm.loggedStreak)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(vm.loggedStreak > 0 ? WatchTheme.successGreen : .secondary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 4)

                ForEach(vm.activeExercises) { exercise in
                    WatchExerciseCard(exercise: exercise, vm: vm)
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
        .onChange(of: vm.allGoalsMet) { _, newValue in
            if newValue && !wasAllGoalsMet {
                WKInterfaceDevice.current().play(.success)
            }
            wasAllGoalsMet = newValue
        }
    }
}

struct WatchExerciseCard: View {
    let exercise: ExerciseType
    var vm: WatchViewModel

    @State private var timerStart: Date? = nil

    private var reps: Int    { vm.totalReps(for: exercise) }
    private var done: Bool   { vm.goalMet(for: exercise) }
    private var progress: Double { vm.progress(for: exercise) }
    private var mvrValue: Int { vm.mvr(for: exercise) }
    private var goal: Int { vm.goal(for: exercise) }
    private var accentColor: Color { done ? WatchTheme.successGreen : WatchTheme.coolBlue }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(exercise.displayName)
                    .font(.headline)
                Spacer()
                Text("\(reps)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(done ? WatchTheme.successGreen : .primary)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * progress, height: 4)
                    if mvrValue > 0 && mvrValue < goal {
                        let mvrX = geo.size.width * Double(mvrValue) / Double(goal)
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 1.5, height: 10)
                            .offset(x: mvrX - 0.75)
                    }
                }
            }
            .frame(height: 4)

            if exercise.isTimerBased {
                watchTimerControls
            } else {
                HStack(spacing: 5) {
                    ForEach(exercise.quickIncrements, id: \.self) { amount in
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            vm.logReps(amount, for: exercise)
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
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var watchTimerControls: some View {
        if let start = timerStart {
            TimelineView(.periodic(from: start, by: 1.0)) { context in
                let elapsed = Int(context.date.timeIntervalSince(start))
                HStack(spacing: 5) {
                    Text(formatElapsed(elapsed))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WatchTheme.successGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        if let s = timerStart {
                            let secs = max(1, Int(Date().timeIntervalSince(s)))
                            WKInterfaceDevice.current().play(.success)
                            vm.logReps(secs, for: exercise)
                            timerStart = nil
                        }
                    } label: {
                        Text("Stop")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Button {
                WKInterfaceDevice.current().play(.click)
                timerStart = Date()
            } label: {
                Text("Start")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(done ? 0.25 : 0.15))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)s"
    }
}
