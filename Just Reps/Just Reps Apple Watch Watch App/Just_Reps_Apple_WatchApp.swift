import SwiftUI
import SwiftData

@main
struct Just_Reps_Apple_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedWatchModelContainer)
    }
}

// Same App Group container as the iOS app — shared SwiftData store.
// Reads the same "JustReps.sqlite" so logging on the watch appears on the phone and vice versa.
private let sharedWatchModelContainer: ModelContainer = {
    let schema = Schema([WorkoutEntry.self, CustomMilestone.self])
    if let groupURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.rylanddean.justreps"),
       let container = try? ModelContainer(for: schema, configurations: [
           ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("JustReps.sqlite"))
       ]) {
        return container
    }
    return try! ModelContainer(for: schema)
}()
