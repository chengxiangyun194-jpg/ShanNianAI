import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var noteStore: NoteStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var isConfigured = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CaptureView()
                .tabItem {
                    Label("捕捉", systemImage: "plus.circle.fill")
                }
                .tag(0)

            NoteListView()
                .tabItem {
                    Label("笔记", systemImage: "list.bullet")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label("洞察", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.orange)
        .onAppear {
            if !isConfigured {
                noteStore.configure(with: modelContext)
                isConfigured = true
            }
        }
        .onOpenURL { url in
            if url.scheme == "shanian" && url.host == "capture" {
                HapticManager.medium()
                selectedTab = 0
            }
        }
    }
}
