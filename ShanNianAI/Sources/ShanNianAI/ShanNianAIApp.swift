import SwiftUI
import SwiftData

@main
struct ShanNianAIApp: App {
    @StateObject private var noteStore = NoteStore()
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("icloud_sync_enabled") private var iCloudSyncEnabled = false

    var modelContainer: ModelContainer {
        do {
            if iCloudSyncEnabled {
                let schema = Schema([Note.self, DailyRecord.self])
                let config = ModelConfiguration(
                    schema: schema,
                    cloudKitContainerIdentifier: "iCloud.com.shanian.flashai"
                )
                return try ModelContainer(for: schema, configurations: config)
            } else {
                let schema = Schema([Note.self, DailyRecord.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: config)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(noteStore)
                    .environmentObject(notificationManager)
                    .modelContainer(modelContainer)
                    .task {
                        await notificationManager.requestAuthorization()
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(noteStore)
                    .environmentObject(notificationManager)
                    .modelContainer(modelContainer)
                    .task {
                        await notificationManager.requestAuthorization()
                    }
            }
        }
    }
}
