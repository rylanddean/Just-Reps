import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("darkModeOverride") private var darkModeOverride = false
    @State private var homeViewModel = HomeViewModel()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainApp
            } else {
                OnboardingView { selectedExercises in
                    homeViewModel.activeExercises = selectedExercises
                }
            }
        }
        .preferredColorScheme(darkModeOverride ? .dark : nil)
    }

    private var mainApp: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            StreakView()
                .tabItem {
                    Label("Streak", systemImage: "flame.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .tint(AppTheme.Colors.successGreen)
    }
}
