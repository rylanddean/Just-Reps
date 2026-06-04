import EventKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [WorkoutEntry]

    @AppStorage("userName")                     private var userName = ""
    @AppStorage("notificationsEnabled")        private var notificationsEnabled = false
    @AppStorage("notificationHour")            private var notificationHour = 18
    @AppStorage("notificationMinute")          private var notificationMinute = 0
    @AppStorage("notificationTimeCustomized")  private var notificationTimeCustomized = false
    @AppStorage("endOfDayReminderEnabled")     private var endOfDayReminderEnabled = true
    @AppStorage("endOfDayHour")               private var endOfDayHour = 18
    @AppStorage("endOfDayMinute")             private var endOfDayMinute = 0
    @AppStorage("healthKitEnabled", store: UserDefaults(suiteName: "group.com.rylanddean.justreps"))
    private var healthKitEnabled = false
    @AppStorage("lastBackupTimestamp")  private var lastBackupTimestamp: Double = 0

    // Workout block
    @AppStorage("workoutBlockEnabled")      private var workoutBlockEnabled = false
    @AppStorage("workoutBlockCalendarID")   private var workoutBlockCalendarID = ""
    @AppStorage("workoutBlockAMEnabled")    private var workoutBlockAMEnabled = true
    @AppStorage("workoutBlockAMStartHour")  private var workoutBlockAMStartHour = 6
    @AppStorage("workoutBlockAMStartMin")   private var workoutBlockAMStartMin = 0
    @AppStorage("workoutBlockAMEndHour")    private var workoutBlockAMEndHour = 12
    @AppStorage("workoutBlockAMEndMin")     private var workoutBlockAMEndMin = 0
    @AppStorage("workoutBlockPMEnabled")    private var workoutBlockPMEnabled = false
    @AppStorage("workoutBlockPMStartHour")  private var workoutBlockPMStartHour = 17
    @AppStorage("workoutBlockPMStartMin")   private var workoutBlockPMStartMin = 0
    @AppStorage("workoutBlockPMEndHour")    private var workoutBlockPMEndHour = 21
    @AppStorage("workoutBlockPMEndMin")     private var workoutBlockPMEndMin = 0

    @State private var reminderTime = Date()
    @State private var endOfDayTime = Date()
    @State private var amStartTime  = Date()
    @State private var amEndTime    = Date()
    @State private var pmStartTime  = Date()
    @State private var pmEndTime    = Date()
    @State private var writableCalendars: [EKCalendar] = []
    @State private var showAddExerciseSheet = false
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

    private let builtInExercises: [ExerciseType] = [.pushups, .squats, .pullups, .situps, .plank, .stretching, .walking]

    var body: some View {
        NavigationStack {
            List {
                profileSection
                exercisesSection
                notificationsSection
                workoutBlockSection
                siriSection
                healthSection
                backupSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
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
                endOfDayTime = makeDate(hour: endOfDayHour, minute: endOfDayMinute)
                amStartTime  = makeDate(hour: workoutBlockAMStartHour, minute: workoutBlockAMStartMin)
                amEndTime    = makeDate(hour: workoutBlockAMEndHour,   minute: workoutBlockAMEndMin)
                pmStartTime  = makeDate(hour: workoutBlockPMStartHour, minute: workoutBlockPMStartMin)
                pmEndTime    = makeDate(hour: workoutBlockPMEndHour,   minute: workoutBlockPMEndMin)
                if workoutBlockEnabled {
                    writableCalendars = WorkoutBlockManager.shared.writableCalendars
                }
            }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            AddCustomExerciseSheet { exercise in
                guard !viewModel.activeExercises.contains(where: { $0.id == exercise.id }) else { return }
                viewModel.activeExercises.append(exercise)
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

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $userName)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .textContentType(.givenName)
                    .foregroundStyle(userName.isEmpty ? Color(UIColor.tertiaryLabel) : Color(UIColor.label))
            }
        }
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        Section(
            header: Text("Exercises"),
            footer: Text("Choose which exercises appear on the home screen. Walking reads your step count automatically from Apple Health.")
        ) {
            ForEach(builtInExercises) { exercise in
                let isActive = viewModel.activeExercises.contains(where: { $0.id == exercise.id })
                Toggle(isOn: Binding(
                    get: { isActive },
                    set: { toggleExercise(exercise, enabled: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.displayName)
                        if exercise.isAutoTracked {
                            Label("Requires Apple Health", systemImage: "heart.fill")
                                .font(AppTheme.Font.caption())
                                .foregroundStyle(.pink.opacity(0.85))
                        } else if !exercise.muscleGroups.isEmpty {
                            Text(exercise.muscleGroups.map(\.displayName).joined(separator: " · "))
                                .font(AppTheme.Font.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(AppTheme.Colors.successGreen)
                .disabled(isActive && viewModel.activeExercises.count == 1)

                if isActive {
                    goalRow(for: exercise)
                }
                // MVR doesn't apply to auto-tracked exercises (goal is in steps, not tapped reps)
                if isActive && !exercise.isAutoTracked {
                    mvrRow(for: exercise)
                }
            }

            ForEach(customExercises, id: \.id) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.displayName)
                            .font(AppTheme.Font.body())
                        if !exercise.muscleGroups.isEmpty {
                            Text(exercise.muscleGroups.map(\.displayName).joined(separator: " · "))
                                .font(AppTheme.Font.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
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
                goalRow(for: exercise)
                mvrRow(for: exercise)
            }

            Button {
                showAddExerciseSheet = true
            } label: {
                Label("Add custom exercise", systemImage: "plus.circle.fill")
                    .foregroundStyle(AppTheme.Colors.successGreen)
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

    private func goalRow(for exercise: ExerciseType) -> some View {
        let minGoal = exercise.isAutoTracked ? 1000 : max(viewModel.mvr(for: exercise) + 1, 1)
        let (range, step): (ClosedRange<Int>, Int) = {
            switch exercise.unit {
            case "steps":    return (1000...50000, 1000)
            case "sec":      return (5...600, 5)
            case "sessions": return (1...20, 1)
            default:         return (1...500, 5)
            }
        }()
        let clampedMin = max(range.lowerBound, minGoal)
        let clampedRange = clampedMin...range.upperBound
        let goalBinding = Binding(
            get: { viewModel.goal(for: exercise) },
            set: { viewModel.setGoal(max($0, clampedMin), for: exercise) }
        )
        let goalValue = viewModel.goal(for: exercise)
        return HStack {
            Text("Daily goal")
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
            Spacer()
            Text(exercise.unit == "steps"
                 ? "\(goalValue.formatted()) steps"
                 : "\(goalValue) \(exercise.unit)")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.successGreen)
                .frame(minWidth: 60, alignment: .trailing)
            Stepper("", value: goalBinding, in: clampedRange, step: step)
                .labelsHidden()
        }
    }

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
                    notificationTimeCustomized = true
                    notifManager.scheduleDailyReminder(hour: h, minute: m)
                }

                Toggle("End of day reminder", isOn: $endOfDayReminderEnabled)
                    .tint(AppTheme.Colors.successGreen)
                    .onChange(of: endOfDayReminderEnabled) { _, enabled in
                        if enabled && !viewModel.allGoalsMet {
                            notifManager.scheduleEndOfDayReminder(
                                hour: endOfDayHour,
                                minute: endOfDayMinute,
                                body: viewModel.endOfDayNotificationBody
                            )
                        } else {
                            notifManager.cancelEndOfDayReminder()
                        }
                    }

                if endOfDayReminderEnabled {
                    DatePicker(
                        "End of day time",
                        selection: $endOfDayTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(AppTheme.Colors.successGreen)
                    .onChange(of: endOfDayTime) { _, newTime in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                        let h = comps.hour ?? 18
                        let m = comps.minute ?? 0
                        endOfDayHour = h
                        endOfDayMinute = m
                        if !viewModel.allGoalsMet {
                            notifManager.scheduleEndOfDayReminder(
                                hour: h,
                                minute: m,
                                body: viewModel.endOfDayNotificationBody
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Siri & Shortcuts

    private var siriSection: some View {
        Section(
            header: Text("Siri & Shortcuts"),
            footer: Text("All four intents appear in the Shortcuts app for automations and Lock Screen shortcuts.")
        ) {
            siriRow(phrase: "What's my Just Reps streak?")
            siriRow(phrase: "Did I log today in Just Reps?")
            siriRow(phrase: "How many reps this week in Just Reps?")
            siriRow(phrase: "What's my longest streak in Just Reps?")
        }
    }

    private func siriRow(phrase: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "waveform")
                .foregroundStyle(AppTheme.Colors.coolBlue)
                .frame(width: 20)
            Text("\u{201C}\(phrase)\u{201D}")
                .font(AppTheme.Font.body())
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

    private func mvrRow(for exercise: ExerciseType) -> some View {
        let mvrBinding = Binding(
            get: { viewModel.mvr(for: exercise) },
            set: { viewModel.setMVR($0, for: exercise) }
        )
        let mvrValue = viewModel.mvr(for: exercise)
        let maxMVR = max(viewModel.goal(for: exercise) - 1, 1)
        return HStack {
            Text("Minimum reps to count the day")
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
            Spacer()
            Text(mvrValue == 0 ? "Off" : "\(mvrValue) \(exercise.unit)")
                .font(AppTheme.Font.headline())
                .foregroundStyle(mvrValue == 0 ? Color.secondary : AppTheme.Colors.successGreen)
                .frame(minWidth: 36, alignment: .trailing)
            Stepper("", value: mvrBinding, in: 0...maxMVR, step: 5)
                .labelsHidden()
        }
    }

    private func toggleExercise(_ exercise: ExerciseType, enabled: Bool) {
        if enabled {
            guard !viewModel.activeExercises.contains(where: { $0.id == exercise.id }) else { return }
            if exercise.isAutoTracked {
                // Request step count read access before adding — HealthKit shows its own prompt
                // if needed; silent on repeat calls.
                Task {
                    await HealthKitManager.shared.requestWalkingAuthorization()
                    viewModel.activeExercises.append(exercise)
                }
            } else {
                viewModel.activeExercises.append(exercise)
            }
        } else {
            viewModel.activeExercises.removeAll { $0.id == exercise.id }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                await notifManager.requestAuthorization()
                if notifManager.isAuthorized {
                    if notificationTimeCustomized {
                        notifManager.scheduleDailyReminder(hour: notificationHour, minute: notificationMinute)
                    } else {
                        notifManager.scheduleSmartReminder(entries: allEntries)
                    }
                } else {
                    notificationsEnabled = false
                }
            }
        } else {
            notifManager.cancelReminder()
            notifManager.cancelEndOfDayReminder()
        }
    }

    // MARK: - Developer (DEBUG only)

    #if DEBUG
    @State private var insightCacheCleared = false

    private var developerSection: some View {
        Section(
            header: Text("Developer"),
            footer: Text("Only visible in debug builds.")
        ) {
            Button {
                clearPulseInsightCache()
                insightCacheCleared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { insightCacheCleared = false }
            } label: {
                HStack {
                    Text(insightCacheCleared ? "Cache cleared" : "Clear Pulse insight cache")
                        .foregroundStyle(insightCacheCleared ? .secondary : AppTheme.Colors.streakDanger)
                    if insightCacheCleared {
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
        }
    }

    private func clearPulseInsightCache() {
        let defaults = UserDefaults.standard
        let prefix = "pulse.insight.v4."
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(prefix) }
            .forEach { defaults.removeObject(forKey: $0) }
    }
    #endif

    // MARK: - Workout block

    private var workoutBlockSection: some View {
        Section(
            header: Text("Workout block"),
            footer: Text("Reserves a 30-min gap in your calendar so there's always a slot for your reps.")
        ) {
            Toggle("Schedule daily block", isOn: $workoutBlockEnabled)
                .tint(AppTheme.Colors.successGreen)
                .onChange(of: workoutBlockEnabled) { _, enabled in
                    Task { await handleWorkoutBlockToggle(enabled) }
                }

            if workoutBlockEnabled {
                if !writableCalendars.isEmpty {
                    Picker("Calendar", selection: $workoutBlockCalendarID) {
                        ForEach(writableCalendars, id: \.calendarIdentifier) { cal in
                            Text(cal.title).tag(cal.calendarIdentifier)
                        }
                    }
                    .tint(AppTheme.Colors.successGreen)
                }

                Toggle("Morning", isOn: $workoutBlockAMEnabled)
                    .tint(AppTheme.Colors.successGreen)
                    .onChange(of: workoutBlockAMEnabled) { _, enabled in
                        if !enabled && !workoutBlockPMEnabled { workoutBlockPMEnabled = true }
                    }

                if workoutBlockAMEnabled {
                    DatePicker("From", selection: $amStartTime, displayedComponents: .hourAndMinute)
                        .tint(AppTheme.Colors.successGreen)
                        .onChange(of: amStartTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            workoutBlockAMStartHour = c.hour ?? 6
                            workoutBlockAMStartMin  = c.minute ?? 0
                        }
                    DatePicker("To", selection: $amEndTime, displayedComponents: .hourAndMinute)
                        .tint(AppTheme.Colors.successGreen)
                        .onChange(of: amEndTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            workoutBlockAMEndHour = c.hour ?? 12
                            workoutBlockAMEndMin  = c.minute ?? 0
                        }
                }

                Toggle("Evening", isOn: $workoutBlockPMEnabled)
                    .tint(AppTheme.Colors.successGreen)
                    .onChange(of: workoutBlockPMEnabled) { _, enabled in
                        if !enabled && !workoutBlockAMEnabled { workoutBlockAMEnabled = true }
                    }

                if workoutBlockPMEnabled {
                    DatePicker("From", selection: $pmStartTime, displayedComponents: .hourAndMinute)
                        .tint(AppTheme.Colors.successGreen)
                        .onChange(of: pmStartTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            workoutBlockPMStartHour = c.hour ?? 17
                            workoutBlockPMStartMin  = c.minute ?? 0
                        }
                    DatePicker("To", selection: $pmEndTime, displayedComponents: .hourAndMinute)
                        .tint(AppTheme.Colors.successGreen)
                        .onChange(of: pmEndTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            workoutBlockPMEndHour = c.hour ?? 21
                            workoutBlockPMEndMin  = c.minute ?? 0
                        }
                }
            }
        }
    }

    private func handleWorkoutBlockToggle(_ enabled: Bool) async {
        guard enabled else { return }
        let granted = await WorkoutBlockManager.shared.requestAccess()
        guard granted else { workoutBlockEnabled = false; return }
        writableCalendars = WorkoutBlockManager.shared.writableCalendars
        if workoutBlockCalendarID.isEmpty {
            workoutBlockCalendarID = WorkoutBlockManager.shared.defaultCalendarID
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

// MARK: - Add Custom Exercise Sheet

private struct AddCustomExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (ExerciseType) -> Void

    @State private var name = ""
    @State private var selectedGroups: Set<MuscleGroup> = []
    @State private var trackingType: TrackingType = .reps

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    nameCard
                    tracksCard
                    targetsCard
                }
                .padding(AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("NAME")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            TextField("e.g. Lunges", text: $name)
                .font(AppTheme.Font.body())
                .padding(AppTheme.Spacing.md)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                .submitLabel(.done)
        }
    }

    private var tracksCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TRACKS")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(TrackingType.allCases, id: \.self) { type in
                    let selected = trackingType == type
                    Button {
                        trackingType = type
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Text(type.displayName)
                            .font(AppTheme.Font.caption())
                            .kerning(0.5)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                selected
                                    ? AppTheme.Colors.successGreen.opacity(0.15)
                                    : Color(UIColor.systemFill)
                            )
                            .foregroundStyle(
                                selected
                                    ? AppTheme.Colors.successGreen
                                    : Color(UIColor.secondaryLabel)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private var targetsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TARGETS")
                .font(AppTheme.Font.caption())
                .kerning(1)
                .foregroundStyle(.secondary)
                .padding(.leading, AppTheme.Spacing.xs)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppTheme.Spacing.sm
            ) {
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    let selected = selectedGroups.contains(group)
                    Button {
                        if selected { selectedGroups.remove(group) }
                        else { selectedGroups.insert(group) }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Text(group.displayName)
                            .font(AppTheme.Font.caption())
                            .kerning(0.5)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                selected
                                    ? AppTheme.Colors.successGreen.opacity(0.15)
                                    : Color(UIColor.systemFill)
                            )
                            .foregroundStyle(
                                selected
                                    ? AppTheme.Colors.successGreen
                                    : Color(UIColor.secondaryLabel)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let groups = MuscleGroup.allCases.filter { selectedGroups.contains($0) }
        onAdd(ExerciseType.custom(name: trimmed, muscleGroups: groups, trackingType: trackingType))
        dismiss()
    }
}
