import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [WorkoutEntry]
    @State private var vm = WatchViewModel()

    var body: some View {
        TabView {
            WatchHomeView(vm: vm, context: context)
                .tag(0)
            WatchStreakView(vm: vm)
                .tag(1)
            WatchActivityView(vm: vm)
                .tag(2)
            WatchTrainingLoadView(vm: vm)
                .tag(3)
            WatchGoalSuggestionsView(vm: vm)
                .tag(4)
            WatchMilestonesView(vm: vm)
                .tag(5)
        }
        .tabViewStyle(.page)
        .onAppear { vm.refresh(with: entries) }
        .onChange(of: entries) { _, updated in vm.refresh(with: updated) }
    }
}

#Preview {
    ContentView()
}
