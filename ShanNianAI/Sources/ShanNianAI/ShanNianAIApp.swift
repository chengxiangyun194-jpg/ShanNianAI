import SwiftUI
import SwiftData

@main
struct ShanNianAIApp: App {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("icloud_sync_enabled") private var iCloudSyncEnabled = false

    @State private var sharedModelContainer: ModelContainer = {
        let schema = Schema([Note.self, DailyRecord.self])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Persistent store unavailable, using in-memory. \(error)")
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: config))!
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(noteStore)
                    .environmentObject(notificationManager)
                    .modelContainer(sharedModelContainer)
                    .task {
                        await notificationManager.requestAuthorization()
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(noteStore)
                    .environmentObject(notificationManager)
                    .modelContainer(sharedModelContainer)
                    .task {
                        await notificationManager.requestAuthorization()
                    }
            }
        }
    }
}
