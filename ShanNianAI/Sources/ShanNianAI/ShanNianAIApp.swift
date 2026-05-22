import SwiftUI
import SwiftData

@main
struct ShanNianAIApp: App {
    @StateObject private var noteStore = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(noteStore)
        }
        .modelContainer(for: Note.self)
    }
}
