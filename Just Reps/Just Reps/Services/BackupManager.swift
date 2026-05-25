import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Codable transfer types

struct WorkoutEntryRecord: Codable {
    var id: UUID
    var exerciseRaw: String
    var reps: Int
    var timestamp: Date
    var effortRPE: Double?
    // Preserves rest/freeze entries across backup/restore cycles.
    var kindRaw: String?
}

struct PreferencesRecord: Codable {
    var activeExercises: [String]
    var dailyGoals: [String: Int]
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var darkModeOverride: Bool
    var healthKitEnabled: Bool
    // Freeze token state — earned by streak milestones, capped at 2.
    var freezeTokens: Int
    var lastFreezeAwardDay: String
}

struct BackupPayload: Codable {
    var version: Int
    var createdAt: Date
    var workoutEntries: [WorkoutEntryRecord]
    var preferences: PreferencesRecord

    static let placeholder = BackupPayload(
        version: 2,
        createdAt: .now,
        workoutEntries: [],
        preferences: PreferencesRecord(
            activeExercises: [],
            dailyGoals: [:],
            notificationsEnabled: false,
            notificationHour: 18,
            notificationMinute: 0,
            darkModeOverride: false,
            healthKitEnabled: false,
            freezeTokens: 0,
            lastFreezeAwardDay: ""
        )
    )
}

// MARK: - FileDocument

struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    var payload: BackupPayload

    init(payload: BackupPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        payload = try decoder.decode(BackupPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - BackupManager

enum BackupManager {
    static let lastBackupKey = "lastBackupDate"

    private static let appGroupID = "group.com.rylanddean.justreps"
    private static let freezeTokensKey = "freezeTokens"
    private static let lastFreezeAwardDayKey = "lastFreezeAwardDay"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func createDocument(entries: [WorkoutEntry]) -> BackupDocument {
        let records = entries.map {
            WorkoutEntryRecord(
                id: $0.id,
                exerciseRaw: $0.exerciseRaw,
                reps: $0.reps,
                timestamp: $0.timestamp,
                effortRPE: $0.effortRPE,
                kindRaw: $0.kindRaw
            )
        }
        let prefs = PreferencesRecord(
            activeExercises: sharedDefaults.stringArray(forKey: "activeExercises") ?? [],
            dailyGoals: sharedDefaults.dictionary(forKey: "dailyGoals") as? [String: Int] ?? [:],
            notificationsEnabled: UserDefaults.standard.bool(forKey: "notificationsEnabled"),
            notificationHour: UserDefaults.standard.integer(forKey: "notificationHour"),
            notificationMinute: UserDefaults.standard.integer(forKey: "notificationMinute"),
            darkModeOverride: UserDefaults.standard.bool(forKey: "darkModeOverride"),
            healthKitEnabled: sharedDefaults.bool(forKey: "healthKitEnabled"),
            freezeTokens: sharedDefaults.integer(forKey: freezeTokensKey),
            lastFreezeAwardDay: sharedDefaults.string(forKey: lastFreezeAwardDayKey) ?? ""
        )
        return BackupDocument(payload: BackupPayload(
            version: 2,
            createdAt: .now,
            workoutEntries: records,
            preferences: prefs
        ))
    }

    static func restore(
        from url: URL,
        context: ModelContext,
        viewModel: HomeViewModel
    ) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        // Replace workout entries (preserving kind for rest/freeze days)
        let existing = try context.fetch(FetchDescriptor<WorkoutEntry>())
        existing.forEach { context.delete($0) }

        for record in payload.workoutEntries {
            let entry = WorkoutEntry(
                exercise: ExerciseType(rawString: record.exerciseRaw),
                reps: record.reps,
                timestamp: record.timestamp,
                effortRPE: record.effortRPE
            )
            entry.id = record.id
            entry.kindRaw = record.kindRaw  // restore rest/freeze classification
            context.insert(entry)
        }

        // Restore preferences
        let prefs = payload.preferences
        sharedDefaults.set(prefs.activeExercises, forKey: "activeExercises")
        sharedDefaults.set(prefs.dailyGoals, forKey: "dailyGoals")
        UserDefaults.standard.set(prefs.notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(prefs.notificationHour, forKey: "notificationHour")
        UserDefaults.standard.set(prefs.notificationMinute, forKey: "notificationMinute")
        UserDefaults.standard.set(prefs.darkModeOverride, forKey: "darkModeOverride")
        sharedDefaults.set(prefs.healthKitEnabled, forKey: "healthKitEnabled")
        // Restore freeze token state (v2+ backups only; older backups default to 0)
        sharedDefaults.set(prefs.freezeTokens, forKey: freezeTokensKey)
        sharedDefaults.set(prefs.lastFreezeAwardDay, forKey: lastFreezeAwardDayKey)

        // Update live view model state
        viewModel.activeExercises = prefs.activeExercises.map { ExerciseType(rawString: $0) }
        viewModel.dailyGoals = prefs.dailyGoals
    }
}
