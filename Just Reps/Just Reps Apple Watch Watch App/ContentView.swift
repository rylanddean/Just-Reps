import SwiftUI

struct ContentView: View {
    @State private var vm = WatchViewModel()
    private let session = WatchSessionManager.shared

    var body: some View {
        TabView {
            WatchHomeView(vm: vm)
                .tag(0)
            WatchStreakView(vm: vm)
                .tag(1)
            WatchActivityView(vm: vm)
                .tag(2)
        }
        .tabViewStyle(.page)
        .onAppear {
            // Apply any cached data that loaded before this view appeared.
            if session.lastUpdate > .distantPast {
                vm.applyPhoneContext(
                    entries: session.entries,
                    exercises: session.exercises,
                    goals: session.goals
                )
            }
        }
        .onChange(of: session.lastUpdate) { _, _ in
            vm.applyPhoneContext(
                entries: session.entries,
                exercises: session.exercises,
                goals: session.goals
            )
        }
    }
}

#Preview {
    ContentView()
}
