import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding")        private var hasCompletedOnboarding = false
    @AppStorage("notificationsEnabled")          private var notificationsEnabled = false
    @AppStorage("notificationTimeCustomized")    private var notificationTimeCustomized = false
    @Environment(\.scenePhase)                   private var scenePhase
    @Environment(\.modelContext)                 private var modelContext
    @Query                                       private var allEntries: [WorkoutEntry]
    @State private var homeViewModel = HomeViewModel()
    @State private var logoOpacity: Double = 1
    @State private var bgOpacity: Double = 1
    @State private var showAtRiskSheet = false

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
            guard phase == .active else { return }
            // Sync Apple Health data every time the app becomes active (launch + foreground return).
            Task {
                async let steps: () = homeViewModel.syncWalkingEntry(context: modelContext)
                async let load: () = HealthKitManager.shared.fetchTrainingLoad()
                _ = await (steps, load)
            }
            let today = StreakEngine.logicalDay(for: .now)
            let hasLoggedToday = allEntries.contains {
                $0.kind == .workout && StreakEngine.logicalDay(for: $0.timestamp) == today
            }
            WorkoutBlockManager.shared.scheduleBlockIfNeeded(hasLoggedToday: hasLoggedToday)
            WorkoutBlockManager.shared.scheduleBackgroundTask()
            guard notificationsEnabled, !notificationTimeCustomized else { return }
            NotificationManager.shared.scheduleSmartReminder(entries: allEntries)
        }
        .onReceive(NotificationCenter.default.publisher(for: .streakAtRiskTapped)) { _ in
            showAtRiskSheet = true
        }
        .sheet(isPresented: $showAtRiskSheet) {
            StreakAtRiskSheet(viewModel: homeViewModel)
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
            PulseView(homeViewModel: homeViewModel)
                .tabItem {
                    Label("Pulse", systemImage: "waveform")
                }

            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Log", systemImage: "pencil")
                }

            ProgressView(homeViewModel: homeViewModel)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
        }
        .tint(AppTheme.Colors.successGreen)
    }
}
