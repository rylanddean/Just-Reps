import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @State private var page = 0
    @State private var nameInput = ""
    @State private var selectedExercises: Set<ExerciseType> = [.pushups, .squats]
    @FocusState private var nameFieldFocused: Bool
    private let builtInExercises: [ExerciseType] = [.pushups, .squats, .pullups, .situps, .plank, .stretching]

    // Passed back to HomeViewModel after onboarding completes
    var onComplete: ([ExerciseType]) -> Void

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            TabView(selection: $page) {
                welcomePage.tag(0)
                nameEntryPage.tag(1)
                exercisePickerPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            // Page dots + CTA at bottom
            VStack {
                Spacer()
                bottomBar
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Text("||||||||||")
                .font(.system(size: 48, weight: .heavy, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.successGreen)
                .kerning(6)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Just Reps")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))

                Text("Show up daily.")
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                featurePill("🔥", "Build a daily streak")
                featurePill("⚡️", "Log reps in one tap")
                featurePill("🧘", "Even 5 reps keeps the chain alive")
                featurePill("👥", "See how friends stack up")
                featurePill("⌚", "Log from your Apple Watch")
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    private func featurePill(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(emoji)
            Text(text)
                .font(AppTheme.Font.body())
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(Capsule())
    }

    // MARK: - Name entry

    private var nameEntryPage: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("What's your name?")
                    .font(AppTheme.Font.title())
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Pulse will use it.")
                    .font(AppTheme.Font.body())
                    .foregroundStyle(.secondary)
            }

            TextField("Your name", text: $nameInput)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .textContentType(.givenName)
                .submitLabel(.next)
                .focused($nameFieldFocused)
                .onSubmit { withAnimation { page = 2 } }
                .padding(AppTheme.Spacing.md)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))

            Spacer()
            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
        .onChange(of: page) { _, newPage in
            if newPage == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Exercise picker

    private var exercisePickerPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Spacer().frame(height: AppTheme.Spacing.xl)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Pick your exercises.")
                        .font(AppTheme.Font.title())
                        .fontWeight(.bold)
                    Text("You can change these any time in Settings.")
                        .font(AppTheme.Font.body())
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(builtInExercises) { exercise in
                        exerciseToggleRow(exercise)
                    }
                }

                Spacer().frame(height: 120) // breathing room above bottom bar
            }
            .padding(AppTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
    }

    private func exerciseToggleRow(_ exercise: ExerciseType) -> some View {
        let isSelected = selectedExercises.contains(exercise)
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if isSelected {
                // Always keep at least one selected
                if selectedExercises.count > 1 { selectedExercises.remove(exercise) }
            } else {
                selectedExercises.insert(exercise)
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Text(exercise.emoji)
                    .font(.title2)
                Text(exercise.displayName)
                    .font(AppTheme.Font.headline())
                    .foregroundStyle(Color(UIColor.label))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.Colors.successGreen : Color(UIColor.tertiaryLabel))
                    .animation(.easeOut(duration: 0.15), value: isSelected)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                isSelected
                    ? AppTheme.Colors.successGreen.opacity(0.1)
                    : Color(UIColor.secondarySystemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(
                        isSelected ? AppTheme.Colors.successGreen.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(page == i ? Color(UIColor.label) : Color(UIColor.tertiaryLabel))
                        .frame(width: page == i ? 20 : 8, height: 8)
                        .animation(.spring(duration: 0.3), value: page)
                }
            }

            // CTA button
            Button(action: handleCTA) {
                Text(ctaLabel)
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(UIColor.label))
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .buttonStyle(.plain)
        }
        .padding(.bottom, AppTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    private var ctaLabel: String {
        switch page {
        case 0: return "Get started"
        case 1: return nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? "Skip" : "Continue"
        default: return "Let's go"
        }
    }

    private func handleCTA() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if page < 2 {
            if page == 1 {
                let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { userName = trimmed }
                nameFieldFocused = false
            }
            withAnimation { page += 1 }
        } else {
            withAnimation {
                hasCompletedOnboarding = true
                onComplete(Array(selectedExercises))
            }
        }
    }
}
