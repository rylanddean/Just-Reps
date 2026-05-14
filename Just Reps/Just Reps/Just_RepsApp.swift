import SwiftUI
import SwiftData

@main
struct Just_RepsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// Shared App Group container so the Watch app reads/writes the same SwiftData store.
// Requires "group.com.rylanddean.justreps" App Group entitlement on both targets.
// Falls back to isolated local storage if the entitlement isn't configured yet.
let sharedModelContainer: ModelContainer = {
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
