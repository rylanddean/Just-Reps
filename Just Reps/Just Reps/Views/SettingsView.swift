import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [WorkoutEntry]

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationHour")     private var notificationHour = 18
    @AppStorage("notificationMinute")   private var notificationMinute = 0
    @AppStorage("healthKitEnabled")     private var healthKitEnabled = false
    @AppStorage("repsPerMinute")        private var repsPerMinute = 20
    @AppStorage("lastBackupTimestamp")  private var lastBackupTimestamp: Double = 0

    @State private var reminderTime = Date()
    @State private var newExerciseName = ""
    @State private var exportDocument = BackupDocument(payload: .placeholder)
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showRestoreConfirm = false
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    private let notifManager = NotificationManager.shared

    private var lastBackupDate: Date? {
        lastBackupTimestamp > 0 ? Date(timeIntervalSinceReferenceDate: lastBackupTimestamp) : nil
    }

    private let builtInExercises: [ExerciseType] = [.pushups, .squats, .pullups, .situps, .plank, .stretching]

    var body: some View {
        NavigationStack {
            List {
                exercisesSection
                notificationsSection
                healthSection
                backupSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await notifManager.checkAuthorizationStatus()
                reminderTime = makeDate(hour: notificationHour, minute: notificationMinute)
            }
        }
        .confirmationDialog(
            "Replace all data?",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button("Restore", role: .destructive) { isImporting = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces all current workout history and settings with the backup.")
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            if case .success = result {
                lastBackupTimestamp = Date().timeIntervalSinceReferenceDate
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        .alert("Backup", isPresented: $showResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage)
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        Section(
            header: Text("Exercises"),
            footer: Text("Choose which exercises appear on the home screen.")
        ) {
            ForEach(builtInExercises) { exercise in
                let isActive = viewModel.activeExercises.contains(where: { $0.id == exercise.id })
                Toggle(isOn: Binding(
                    get: { isActive },
                    set: { toggleExercise(exercise, enabled: $0) }
                )) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(exercise.emoji)
                        Text(exercise.displayName)
                    }
                }
                .tint(AppTheme.Colors.successGreen)
                .disabled(isActive && viewModel.activeExercises.count == 1)
            }

            ForEach(customExercises, id: \.id) { exercise in
                HStack {
                    Text(exercise.emoji)
                        .font(.body)
                    Text(exercise.displayName)
                        .font(AppTheme.Font.body())
                    Spacer()
                    Button {
                        guard viewModel.activeExercises.count > 1 else { return }
                        viewModel.activeExercises.removeAll { $0.id == exercise.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(viewModel.activeExercises.count > 1 ? .red : Color(UIColor.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                TextField("Add custom exercise…", text: $newExerciseName)
                    .submitLabel(.done)
                    .onSubmit { addCustomExercise() }

                Button { addCustomExercise() } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Color(UIColor.tertiaryLabel)
                                         : AppTheme.Colors.successGreen)
                }
                .buttonStyle(.plain)
                .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var customExercises: [ExerciseType] {
        viewModel.activeExercises.filter {
            if case .custom = $0 { return true }
            return false
        }
    }

    // MARK: - Goals

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Reminders") {
            Toggle("Daily reminder", isOn: $notificationsEnabled)
                .tint(AppTheme.Colors.successGreen)
                .onChange(of: notificationsEnabled) { _, enabled in
                    handleNotificationToggle(enabled)
                }

            if notificationsEnabled {
                DatePicker(
                    "Reminder time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .tint(AppTheme.Colors.successGreen)
                .onChange(of: reminderTime) { _, newTime in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                    let h = comps.hour ?? 18
                    let m = comps.minute ?? 0
                    notificationHour = h
                    notificationMinute = m
                    notifManager.scheduleDailyReminder(hour: h, minute: m)
                }
            }
        }
    }

    // MARK: - Health

    private var healthSection: some View {
        Section(
            header: Text("Health & Activity"),
            footer: Text("Credit your Apple exercise ring based on reps logged.")
        ) {
            Toggle("Credit exercise ring", isOn: $healthKitEnabled)
                .tint(AppTheme.Colors.successGreen)
                .onChange(of: healthKitEnabled) { _, enabled in
                    guard enabled else { return }
                    Task {
                        let granted = await HealthKitManager.shared.requestAuthorization()
                        if !granted { healthKitEnabled = false }
                    }
                }

            if healthKitEnabled {
                HStack {
                    Text("Reps per minute")
                    Spacer()
                    Text("\(repsPerMinute)")
                        .font(AppTheme.Font.headline())
                        .frame(minWidth: 36, alignment: .trailing)
                    Stepper("", value: $repsPerMinute, in: 5...120, step: 5)
                        .labelsHidden()
                }
            }
        }
    }

    // MARK: - Backup

    private var backupSection: some View {
        Section(
            header: Text("Backup"),
            footer: Text("Saves all workout history and settings. Save to iCloud Drive to restore on a new device.")
        ) {
            Button("Back Up Now") {
                exportDocument = BackupManager.createDocument(entries: allEntries)
                isExporting = true
            }

            if let date = lastBackupDate {
                LabeledContent("Last backup") {
                    Text(date, style: .date)
                        .foregroundStyle(.secondary)
                        .font(AppTheme.Font.caption())
                }
            }

            Button("Restore from Backup…") {
                showRestoreConfirm = true
            }
            .foregroundStyle(AppTheme.Colors.streakDanger)
        }
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "JustReps_Backup_\(formatter.string(from: .now)).json"
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            try BackupManager.restore(from: url, context: modelContext, viewModel: viewModel)
            lastBackupTimestamp = Date().timeIntervalSinceReferenceDate
            resultMessage = "Backup restored."
        } catch {
            resultMessage = "Restore failed."
        }
        showResultAlert = true
    }

    // MARK: - Helpers

    private func toggleExercise(_ exercise: ExerciseType, enabled: Bool) {
        if enabled {
            guard !viewModel.activeExercises.contains(where: { $0.id == exercise.id }) else { return }
            viewModel.activeExercises.append(exercise)
        } else {
            viewModel.activeExercises.removeAll { $0.id == exercise.id }
        }
    }

    private func addCustomExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let exercise = ExerciseType.custom(name: name)
        guard !viewModel.activeExercises.contains(where: { $0.id == exercise.id }) else { return }
        viewModel.activeExercises.append(exercise)
        newExerciseName = ""
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                await notifManager.requestAuthorization()
                if notifManager.isAuthorized {
                    notifManager.scheduleDailyReminder(hour: notificationHour, minute: notificationMinute)
                } else {
                    notificationsEnabled = false
                }
            }
        } else {
            notifManager.cancelReminder()
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Version") {
                Text(appVersionString)
                    .foregroundStyle(.secondary)
                    .font(AppTheme.Font.caption())
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? .now
    }
}
