import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding")        private var hasCompletedOnboarding = false
    @AppStorage("notificationsEnabled")          private var notificationsEnabled = false
    @AppStorage("notificationTimeCustomized")    private var notificationTimeCustomized = false
    @Environment(\.scenePhase)                   private var scenePhase
    @Query                                       private var allEntries: [WorkoutEntry]
    @State private var homeViewModel = HomeViewModel()
    @State private var logoOpacity: Double = 1
    @State private var bgOpacity: Double = 1

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
        .overlay {
            if bgOpacity > 0 {
                splashScreen
                    .ignoresSafeArea()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeOut(duration: 0.35)) {
                logoOpacity = 0
            }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.easeOut(duration: 0.35)) {
                bgOpacity = 0
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active,
                  notificationsEnabled,
                  !notificationTimeCustomized else { return }
            NotificationManager.shared.scheduleSmartReminder(entries: allEntries)
        }
    }

    private var splashScreen: some View {
        ZStack {
            Color.black.opacity(bgOpacity)
            VStack(spacing: AppTheme.Spacing.md) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                Text(versionString)
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(logoOpacity)
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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
